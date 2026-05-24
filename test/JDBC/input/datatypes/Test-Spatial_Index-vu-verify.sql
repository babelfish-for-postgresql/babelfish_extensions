-- ============================================================
-- SESSION-LEVEL GUC CONFIGURATION
-- ============================================================
SELECT set_config('babelfishpg_tsql.explain_verbose',  'off', false)
SELECT set_config('babelfishpg_tsql.explain_costs',    'off', false)
SELECT set_config('babelfishpg_tsql.explain_timing',   'off', false)
SELECT set_config('babelfishpg_tsql.explain_summary',  'off', false)
SELECT set_config('babelfishpg_tsql.explain_buffers',  'off', false)
SELECT set_config('babelfishpg_tsql.explain_wal',      'off', false)
SELECT set_config('babelfishpg_tsql.explain_settings', 'off', false)
SELECT set_config('max_parallel_workers_per_gather', '0', false)
SELECT set_config('enable_seqscan',    'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
GO

-- ============================================================
-- SECTION 1: DDL ERROR CASES
-- ============================================================
-- 1.1 CREATE on non-spatial column (should error)
CREATE SPATIAL INDEX si_bad ON si_ddl_tbl(name);
GO

-- 1.2 Duplicate index name
CREATE SPATIAL INDEX si_dup ON si_ddl_tbl(geom);
GO
CREATE SPATIAL INDEX si_dup ON si_ddl_tbl(geom);
GO

-- 1.3 DROP and recreate
DROP INDEX si_dup ON si_ddl_tbl;
GO
CREATE SPATIAL INDEX si_dup ON si_ddl_tbl(geom);
GO
DROP INDEX si_dup ON si_ddl_tbl;
GO

-- 1.4 DROP non-existent (should error)
DROP INDEX si_fake ON si_ddl_tbl;
GO

-- 1.5 Strict escape hatch blocks options
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_spatial_index', 'strict';
GO
CREATE SPATIAL INDEX si_strict ON si_ddl_tbl(geom)
USING GEOMETRY_GRID WITH (BOUNDING_BOX = (0, 0, 100, 100));
GO

-- 1.6 Bare works with strict
CREATE SPATIAL INDEX si_bare ON si_ddl_tbl(geom);
GO
DROP INDEX si_bare ON si_ddl_tbl;
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_spatial_index', 'ignore';
GO

-- ============================================================
-- SECTION 2: STIntersects REWRITER
-- ============================================================

-- 2.1 col.STIntersects(poly) = 1
SELECT set_config('enable_seqscan', 'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO

SELECT COUNT(*) AS t2_1 FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
GO

-- 2.2 Reversed: 1 = col.STIntersects(poly)
SELECT COUNT(*) AS t2_2 FROM si_geom_tbl
WHERE 1 = si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326));
GO

-- 2.3 = 0
SELECT COUNT(*) AS t2_3 FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 0;
GO

-- 2.4 Whitespace
SELECT COUNT(*) AS t2_4 FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326))  =   1  ;
GO

-- 2.5 SELECT list (no injection)
SET BABELFISH_STATISTICS PROFILE OFF;
GO
SELECT TOP 3 id, si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) AS val
FROM si_geom_tbl ORDER BY id;
GO
SELECT set_config('enable_seqscan', 'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO

-- 2.6 Correctness: normal = reversed
DECLARE @n INT, @r INT;
SELECT @n = COUNT(*) FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
SELECT @r = COUNT(*) FROM si_geom_tbl
WHERE 1 = si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326));
SELECT CASE WHEN @n = @r THEN 'PASS' ELSE 'FAIL' END AS t2_6;
GO

-- 2.7 =1 + =0 = total
DECLARE @yes INT, @no INT;
SELECT @yes = COUNT(*) FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
SELECT @no = COUNT(*) FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 0;
SELECT CASE WHEN @yes + @no = 1000 THEN 'PASS' ELSE 'FAIL' END AS t2_7;
GO

SET BABELFISH_STATISTICS PROFILE OFF;
GO

-- ============================================================
-- SECTION 3: STDistance REWRITER
-- ============================================================
SELECT set_config('enable_seqscan', 'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO

SELECT COUNT(*) AS t3_lt FROM si_geom_tbl
WHERE si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326)) < 100;
GO

SELECT COUNT(*) AS t3_le FROM si_geom_tbl
WHERE si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326)) <= 100;
GO

SELECT COUNT(*) AS t3_gt FROM si_geom_tbl
WHERE si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326)) > 100;
GO

SELECT COUNT(*) AS t3_reversed FROM si_geom_tbl
WHERE 100 > si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326));
GO

DECLARE @d FLOAT = 100;
SELECT COUNT(*) AS t3_var FROM si_geom_tbl
WHERE si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326)) < @d;
GO

SELECT COUNT(*) AS t3_eq0 FROM si_geom_tbl
WHERE si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326)) = 0;
GO

SELECT COUNT(*) AS t3_band FROM si_geom_tbl
WHERE si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326)) > 50
  AND si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326)) < 150;
GO

-- Correctness: < = reversed >
DECLARE @lhs INT, @rhs INT;
SELECT @lhs = COUNT(*) FROM si_geom_tbl
WHERE si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326)) < 100;
SELECT @rhs = COUNT(*) FROM si_geom_tbl
WHERE 100 > si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326));
SELECT CASE WHEN @lhs = @rhs THEN 'PASS' ELSE 'FAIL' END AS t3_correctness;
GO

SET BABELFISH_STATISTICS PROFILE OFF;
GO

-- ============================================================
-- SECTION 4: STContains
-- ============================================================
SELECT set_config('enable_seqscan', 'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO
SELECT COUNT(*) AS t4_contains FROM si_geom_tbl
WHERE geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)
    .STContains(si_geom_tbl.geom) = 1;
GO

SELECT COUNT(*) AS t4_reversed FROM si_geom_tbl
WHERE 1 = geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)
    .STContains(si_geom_tbl.geom);
GO

SET BABELFISH_STATISTICS PROFILE OFF;
GO

-- ============================================================
-- SECTION 5: QUERY CONTEXTS
-- ============================================================
SELECT set_config('enable_seqscan', 'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO
-- Alias
SELECT COUNT(*) AS t5_alias FROM si_geom_tbl t
WHERE t.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
GO

-- JOIN
SET BABELFISH_STATISTICS PROFILE OFF;
GO
SELECT COUNT(*) AS t5_join
FROM si_geom_tbl a INNER JOIN si_geom_tbl b ON a.id = b.id
WHERE a.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1
AND a.id < 100;
GO
SELECT set_config('enable_seqscan', 'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO

-- Subquery
SELECT COUNT(*) AS t5_subq
FROM (SELECT id, geom FROM si_geom_tbl WHERE id < 500) sub
WHERE sub.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
GO

-- OR
SET BABELFISH_STATISTICS PROFILE OFF;
GO
SELECT COUNT(*) AS t5_or FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 150 100, 150 150, 100 150, 100 100))', 4326)) = 1
OR si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((800 800, 850 800, 850 850, 800 850, 800 800))', 4326)) = 1;
GO
SELECT set_config('enable_seqscan', 'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO

-- Combined spatial + non-spatial
SELECT COUNT(*) AS t5_combined FROM si_geom_tbl
WHERE si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326)) < 100
  AND id > 500;
GO

-- CASE (no injection)
SET BABELFISH_STATISTICS PROFILE OFF;
GO
SELECT TOP 3 id,
    CASE WHEN si_geom_tbl.geom.STIntersects(
        geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1
    THEN 'IN' ELSE 'OUT' END AS status
FROM si_geom_tbl ORDER BY id;
GO

-- ============================================================
-- SECTION 6: NULL AND EDGE DATA
-- ============================================================

SELECT set_config('enable_seqscan', 'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO

-- NULL row
INSERT INTO si_geom_tbl (geom) VALUES (NULL);
GO

SELECT COUNT(*) AS t6_null FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
GO

-- LINESTRING
INSERT INTO si_geom_tbl (geom) VALUES (geometry::STGeomFromText('LINESTRING(0 0, 500 500)', 4326));
GO

-- POLYGON
INSERT INTO si_geom_tbl (geom) VALUES (geometry::STGeomFromText('POLYGON((400 400, 600 400, 600 600, 400 600, 400 400))', 4326));
GO

SELECT COUNT(*) AS t6_mixed FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((450 450, 550 450, 550 550, 450 550, 450 450))', 4326)) = 1;
GO

SET BABELFISH_STATISTICS PROFILE OFF;
GO

-- ============================================================
-- SECTION 7: MULTIPLE INDEXES
-- ============================================================
SELECT set_config('enable_seqscan', 'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO

SELECT COUNT(*) AS t7_g1 FROM si_multi_tbl
WHERE si_multi_tbl.g1.STIntersects(
    geometry::STGeomFromText('POLYGON((50 50, 100 50, 100 100, 50 100, 50 50))', 4326)) = 1;
GO

SELECT COUNT(*) AS t7_g2 FROM si_multi_tbl
WHERE si_multi_tbl.g2.STIntersects(
    geometry::STGeomFromText('POLYGON((600 600, 700 600, 700 700, 600 700, 600 600))', 4326)) = 1;
GO

SET BABELFISH_STATISTICS PROFILE OFF;
GO
SELECT COUNT(*) AS t7_both FROM si_multi_tbl
WHERE si_multi_tbl.g1.STIntersects(
    geometry::STGeomFromText('POLYGON((50 50, 100 50, 100 100, 50 100, 50 50))', 4326)) = 1
AND si_multi_tbl.g2.STIntersects(
    geometry::STGeomFromText('POLYGON((600 600, 700 600, 700 700, 600 700, 600 600))', 4326)) = 1;
GO

-- ============================================================
-- SECTION 8: TRANSACTIONS
-- ============================================================
SELECT set_config('enable_seqscan', 'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO

SELECT COUNT(*) AS t8_baseline FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
GO

BEGIN TRANSACTION;
INSERT INTO si_geom_tbl (geom) VALUES (geometry::STGeomFromText('POINT(150 150)', 4326));
INSERT INTO si_geom_tbl (geom) VALUES (geometry::STGeomFromText('POINT(150 150)', 4326));
ROLLBACK;
GO

SELECT COUNT(*) AS t8_after_rollback FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
GO

BEGIN TRANSACTION;
DELETE FROM si_geom_tbl WHERE id <= 50;
ROLLBACK;
GO

SELECT COUNT(*) AS t8_after_del_rb FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
GO

BEGIN TRANSACTION;
INSERT INTO si_geom_tbl (geom) VALUES (geometry::STGeomFromText('POINT(150 150)', 4326));
COMMIT;
GO

SELECT COUNT(*) AS t8_after_commit FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
GO


SET BABELFISH_STATISTICS PROFILE OFF;
GO
-- ============================================================
-- SECTION 9: SYSTEM VIEWS
-- ============================================================

SELECT name, type, type_desc, spatial_index_type, spatial_index_type_desc, tessellation_scheme
FROM sys.spatial_indexes
WHERE object_id = OBJECT_ID('si_view_tbl')
ORDER BY name;
GO

SELECT si.name, sit.tessellation_scheme
FROM sys.spatial_index_tessellations sit
JOIN sys.spatial_indexes si ON si.object_id = sit.object_id AND si.index_id = sit.index_id
WHERE sit.object_id = OBJECT_ID('si_view_tbl')
ORDER BY si.name;
GO

SELECT name, type, type_desc
FROM sys.indexes
WHERE object_id = OBJECT_ID('si_view_tbl')
ORDER BY name
GO

-- ============================================================
-- SECTION 10: GEOGRAPHY
-- ============================================================
SELECT set_config('enable_seqscan', 'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO

SELECT COUNT(*) AS t10_intersects FROM si_geog_tbl
WHERE si_geog_tbl.geog.STIntersects(
    geography::STGeomFromText('POLYGON((-50 -50, 50 -50, 50 50, -50 50, -50 -50))', 4326)) = 1;
GO

SELECT COUNT(*) AS t10_reversed FROM si_geog_tbl
WHERE 1 = si_geog_tbl.geog.STIntersects(
    geography::STGeomFromText('POLYGON((-50 -50, 50 -50, 50 50, -50 50, -50 -50))', 4326));
GO

SELECT COUNT(*) AS t10_dist FROM si_geog_tbl
WHERE si_geog_tbl.geog.STDistance(geography::STGeomFromText('POINT(0 0)', 4326)) < 5000000;
GO

DECLARE @g1 INT, @g2 INT;
SELECT @g1 = COUNT(*) FROM si_geog_tbl
WHERE si_geog_tbl.geog.STIntersects(
    geography::STGeomFromText('POLYGON((-50 -50, 50 -50, 50 50, -50 50, -50 -50))', 4326)) = 1;
SELECT @g2 = COUNT(*) FROM si_geog_tbl
WHERE 1 = si_geog_tbl.geog.STIntersects(
    geography::STGeomFromText('POLYGON((-50 -50, 50 -50, 50 50, -50 50, -50 -50))', 4326));
SELECT CASE WHEN @g1 = @g2 THEN 'PASS' ELSE 'FAIL' END AS t10_correctness;
GO

SET BABELFISH_STATISTICS PROFILE OFF;
GO
-- ============================================================
-- SECTION 11: INDEX + CORRECTNESS (indexed vs seq scan)
-- ============================================================
SELECT set_config('enable_seqscan', 'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO

DECLARE @a INT, @b INT;
SELECT @a = COUNT(*) FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
SELECT @b = COUNT(*) FROM si_geom_tbl WITH (INDEX(0))
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
SELECT CASE WHEN @a = @b THEN 'PASS' ELSE 'FAIL' END AS t11_idx_correctness;
GO


SET BABELFISH_STATISTICS PROFILE OFF;
GO
-- ============================================================
-- SECTION 12: DDL EDGE CASES 
-- ============================================================

-- 12.1 DROP INDEX IF EXISTS on non-existent index (should succeed silently)
DROP INDEX IF EXISTS si_never_created ON si_ddl_tbl;
GO

-- 12.2 DROP INDEX IF EXISTS after successful create + drop
CREATE SPATIAL INDEX si_ifex ON si_ddl_tbl(geom);
GO
DROP INDEX IF EXISTS si_ifex ON si_ddl_tbl;
GO
DROP INDEX IF EXISTS si_ifex ON si_ddl_tbl;
GO

-- ============================================================
-- SECTION 13: STIntersects WHITESPACE AND NOT 
-- ============================================================
SELECT set_config('enable_seqscan', 'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO

-- 13.1 Tab + newline between tokens
SELECT COUNT(*) AS t13_1 FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326))	=
1;
GO

-- 13.2 NOT(col.STIntersects(poly) = 1)
SELECT COUNT(*) AS t13_2 FROM si_geom_tbl
WHERE NOT (si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1)
  AND si_geom_tbl.geom IS NOT NULL;
GO

-- 13.3 NOT correctness: NOT(=1) AND NOT NULL = =0
DECLARE @not1 INT, @eq0 INT;
SELECT @not1 = COUNT(*) FROM si_geom_tbl
WHERE NOT (si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1)
  AND si_geom_tbl.geom IS NOT NULL;
SELECT @eq0 = COUNT(*) FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 0;
SELECT CASE WHEN @not1 = @eq0 THEN 'PASS' ELSE 'FAIL' END AS t13_3;
GO

SET BABELFISH_STATISTICS PROFILE OFF;
GO

-- ============================================================
-- SECTION 14: STDistance >= AND CORRECTNESS (gap fill)
-- ============================================================
SELECT set_config('enable_seqscan', 'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO

-- 14.1 >= 100
SELECT COUNT(*) AS t14_ge FROM si_geom_tbl
WHERE si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326)) >= 100
  AND si_geom_tbl.geom IS NOT NULL;
GO

-- 14.2 Reversed >=: 100 <= col.STDistance(...)
SELECT COUNT(*) AS t14_le_rev FROM si_geom_tbl
WHERE 100 <= si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326))
  AND si_geom_tbl.geom IS NOT NULL;
GO

-- 14.3 Correctness: <= equals reversed >=
DECLARE @le INT, @rge INT;
SELECT @le = COUNT(*) FROM si_geom_tbl
WHERE si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326)) <= 100;
SELECT @rge = COUNT(*) FROM si_geom_tbl
WHERE 100 >= si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326));
SELECT CASE WHEN @le = @rge THEN 'PASS' ELSE 'FAIL' END AS t14_3;
GO

-- 14.4 Correctness: >= equals reversed <=
DECLARE @ge INT, @rle INT;
SELECT @ge = COUNT(*) FROM si_geom_tbl
WHERE si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326)) >= 100;
SELECT @rle = COUNT(*) FROM si_geom_tbl
WHERE 100 <= si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326));
SELECT CASE WHEN @ge = @rle THEN 'PASS' ELSE 'FAIL' END AS t14_4;
GO


SET BABELFISH_STATISTICS PROFILE OFF;
GO

-- ============================================================
-- SECTION 15: STContains SYMMETRY 
-- ============================================================
SET BABELFISH_STATISTICS PROFILE OFF;
GO

-- 15.1 = 0
SELECT COUNT(*) AS t15_eq0 FROM si_geom_tbl
WHERE geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)
    .STContains(si_geom_tbl.geom) = 0;
GO

-- 15.2 Reversed 0 = ...
SELECT COUNT(*) AS t15_eq0_rev FROM si_geom_tbl
WHERE 0 = geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)
    .STContains(si_geom_tbl.geom);
GO

-- 15.3 Correctness: =1 vs reversed 1=
DECLARE @c1 INT, @c1r INT;
SELECT @c1 = COUNT(*) FROM si_geom_tbl
WHERE geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)
    .STContains(si_geom_tbl.geom) = 1;
SELECT @c1r = COUNT(*) FROM si_geom_tbl
WHERE 1 = geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)
    .STContains(si_geom_tbl.geom);
SELECT CASE WHEN @c1 = @c1r THEN 'PASS' ELSE 'FAIL' END AS t15_3;
GO

SET BABELFISH_STATISTICS PROFILE OFF;
GO
-- ============================================================
-- SECTION 16: NULL CONSERVATION
-- ============================================================
SET BABELFISH_STATISTICS PROFILE OFF;
GO
-- count(=1) + count(=0) + count(NULL geom) = total rows
DECLARE @yes INT, @no INT, @nul INT, @tot INT;
SELECT @yes = COUNT(*) FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
SELECT @no = COUNT(*) FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 0;
SELECT @nul = COUNT(*) FROM si_geom_tbl WHERE si_geom_tbl.geom IS NULL;
SELECT @tot = COUNT(*) FROM si_geom_tbl;
SELECT CASE WHEN @yes + @no + @nul = @tot THEN 'PASS' ELSE 'FAIL' END AS t16_conservation;
GO

-- ============================================================
-- SECTION 17: SYSTEM VIEWS STABLE ORDER 
-- ============================================================
SET BABELFISH_STATISTICS PROFILE OFF;
GO

SELECT name, type, type_desc
FROM sys.indexes
WHERE object_id = OBJECT_ID('si_view_tbl')
ORDER BY name;
GO

-- ============================================================
-- SECTION 18: FORCED INDEX USE 
-- ============================================================

SELECT set_config('enable_seqscan', 'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO

-- 18.1 WITH (INDEX(si_v_geom)) forces named index; count must match seq scan
DECLARE @seq INT, @idx INT;
SELECT @seq = COUNT(*) FROM si_view_tbl WITH (INDEX(0))
WHERE si_view_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((0 0, 1000 0, 1000 1000, 0 1000, 0 0))', 4326)) = 1;
SELECT @idx = COUNT(*) FROM si_view_tbl WITH (INDEX(si_v_geom))
WHERE si_view_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((0 0, 1000 0, 1000 1000, 0 1000, 0 0))', 4326)) = 1;
SELECT CASE WHEN @seq = @idx THEN 'PASS' ELSE 'FAIL' END AS t18_forced_idx;
GO

SET BABELFISH_STATISTICS PROFILE OFF;
GO
-- ============================================================
-- SECTION 19: CROSS-TYPE AND SRID EDGE CASES 
-- ============================================================
SELECT set_config('enable_seqscan', 'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO

-- 19.1 geometry.STIntersects(geography) should error
SELECT COUNT(*) AS t19_xtype FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geography::STGeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))', 4326)) = 1;
GO

-- 19.2 SRID mismatch between column (4326) and literal (0)
SELECT COUNT(*) AS t19_srid FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 0)) = 1;
GO

SET BABELFISH_STATISTICS PROFILE OFF;
GO

-- ============================================================
-- SECTION 20: EMPTY GEOMETRY 
-- ============================================================

-- 20.1 Insert and query empty point
INSERT INTO si_geom_tbl (geom) VALUES (geometry::STGeomFromText('POINT EMPTY', 4326));
GO

SELECT COUNT(*) AS t20_empty FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
GO

-- 20.2 Predicate against empty polygon literal
SELECT COUNT(*) AS t20_emptyrhs FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON EMPTY', 4326)) = 1;
GO

-- ============================================================
-- SECTION 21: VARIABLE-BOUND PREDICATE (parameterized pattern)
-- ============================================================
SELECT set_config('enable_seqscan', 'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO

-- 21.1 Variable-bound polygon reused in predicate
DECLARE @poly sys.GEOMETRY = geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326);
SELECT COUNT(*) AS t21_var FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(@poly) = 1;
GO

-- 21.2 Correctness: variable-bound matches literal
DECLARE @poly sys.GEOMETRY = geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326);
DECLARE @v INT, @l INT;
SELECT @v = COUNT(*) FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(@poly) = 1;
SELECT @l = COUNT(*) FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
SELECT CASE WHEN @v = @l THEN 'PASS' ELSE 'FAIL' END AS t21_var_correctness;
GO

SET BABELFISH_STATISTICS PROFILE OFF;
GO

-- ============================================================
-- SECTION 22: STORED PROCEDURE AND FUNCTION BODY
-- ============================================================

-- 22.1 Predicate inside a stored procedure
CREATE PROCEDURE p_spatial_count
    @xmin FLOAT, @ymin FLOAT, @xmax FLOAT, @ymax FLOAT
AS
BEGIN
    DECLARE @wkt VARCHAR(200) = 'POLYGON((' +
        CAST(@xmin AS VARCHAR) + ' ' + CAST(@ymin AS VARCHAR) + ', ' +
        CAST(@xmax AS VARCHAR) + ' ' + CAST(@ymin AS VARCHAR) + ', ' +
        CAST(@xmax AS VARCHAR) + ' ' + CAST(@ymax AS VARCHAR) + ', ' +
        CAST(@xmin AS VARCHAR) + ' ' + CAST(@ymax AS VARCHAR) + ', ' +
        CAST(@xmin AS VARCHAR) + ' ' + CAST(@ymin AS VARCHAR) + '))';
    SELECT COUNT(*) AS t22_proc FROM si_geom_tbl
    WHERE si_geom_tbl.geom.STIntersects(geometry::STGeomFromText(@wkt, 4326)) = 1;
END;
GO

EXEC p_spatial_count 100, 100, 200, 200;
GO

DROP PROCEDURE p_spatial_count;
GO

-- 22.2 Predicate inside IF block
DECLARE @cnt INT;
IF EXISTS (SELECT 1 FROM si_geom_tbl
           WHERE si_geom_tbl.geom.STIntersects(
               geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1)
    SELECT @cnt = COUNT(*) FROM si_geom_tbl
    WHERE si_geom_tbl.geom.STIntersects(
        geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
ELSE
    SELECT @cnt = 0;
SELECT CASE WHEN @cnt > 0 THEN 'PASS' ELSE 'FAIL' END AS t22_if;
GO

-- ============================================================
-- SECTION 23: DML WITH SPATIAL WHERE
-- ============================================================

-- 23.1 DELETE with spatial predicate (rollback so rest of suite unaffected)
BEGIN TRANSACTION;
DELETE FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
ROLLBACK;
GO

-- 23.2 UPDATE with spatial predicate (rollback)
BEGIN TRANSACTION;
UPDATE si_geom_tbl SET geom = NULL
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
ROLLBACK;
GO

-- 23.3 Verify DML rolled back cleanly (count should match pre-DML baseline)
SELECT COUNT(*) AS t23_after_dml FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
GO

-- ============================================================
-- SECTION 24: LEFT JOIN WITH SPATIAL ON CLAUSE
-- ============================================================
-- 24.1 LEFT JOIN with spatial predicate in ON
SELECT COUNT(*) AS t24_left FROM si_geom_tbl a
LEFT JOIN si_geom_tbl b
    ON a.geom.STIntersects(
        geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1
   AND a.id = b.id
WHERE a.id < 20;
GO

-- ============================================================
-- SECTION 25: HAVING WITH SPATIAL PREDICATE
-- ============================================================

-- 25.1 GROUP BY + HAVING with spatial predicate
SELECT TOP 3 id, COUNT(*) AS c
FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1
GROUP BY id
HAVING COUNT(*) >= 1
ORDER BY id;
GO

-- ============================================================
-- SECTION 26: UNION
-- ============================================================

-- 26.1 UNION ALL of spatial queries; each branch must be rewritten
SELECT COUNT(*) AS t26_union FROM (
    SELECT id FROM si_geom_tbl
    WHERE si_geom_tbl.geom.STIntersects(
        geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1
    UNION ALL
    SELECT id FROM si_geom_tbl
    WHERE si_geom_tbl.geom.STIntersects(
        geometry::STGeomFromText('POLYGON((800 800, 900 800, 900 900, 800 900, 800 800))', 4326)) = 1
) u;
GO

-- ============================================================
-- SECTION 27: INDEX LIFECYCLE (drop + recreate)
-- ============================================================

-- 27.1 Baseline count with existing index
DECLARE @before INT;
SELECT @before = COUNT(*) FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
SELECT @before AS t27_before;
GO

-- 27.2 Drop and recreate the index, verify count unchanged
DROP INDEX si_geom ON si_geom_tbl;
GO
CREATE SPATIAL INDEX si_geom ON si_geom_tbl(geom)
USING GEOMETRY_GRID WITH (BOUNDING_BOX = (0, 0, 1000, 1000));
GO

DECLARE @after INT;
SELECT @after = COUNT(*) FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
SELECT @after AS t27_after;
GO

-- ============================================================
-- SECTION 28: CTE (WITH clause)
-- ============================================================

-- 28.1 Spatial predicate inside a CTE
WITH cte AS (
    SELECT id, geom FROM si_geom_tbl
    WHERE si_geom_tbl.geom.STIntersects(
        geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1
)
SELECT COUNT(*) AS t28_cte FROM cte;
GO

-- 28.2 Correctness: CTE count matches direct SELECT
DECLARE @c INT, @d INT;
WITH cte AS (
    SELECT id FROM si_geom_tbl
    WHERE si_geom_tbl.geom.STIntersects(
        geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1
)
SELECT @c = COUNT(*) FROM cte;
SELECT @d = COUNT(*) FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
SELECT CASE WHEN @c = @d THEN 'PASS' ELSE 'FAIL' END AS t28_cte_correctness;
GO

-- ============================================================
-- SECTION 29: EXISTS / NOT EXISTS SUBQUERY
-- ============================================================

-- 29.1 EXISTS with spatial predicate in subquery
SELECT COUNT(*) AS t29_exists FROM si_geom_tbl outer_t
WHERE EXISTS (
    SELECT 1 FROM si_geom_tbl inner_t
    WHERE inner_t.id = outer_t.id
      AND inner_t.geom.STIntersects(
          geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1
);
GO

-- 29.2 NOT EXISTS with spatial predicate
SELECT COUNT(*) AS t29_notexists FROM si_geom_tbl outer_t
WHERE NOT EXISTS (
    SELECT 1 FROM si_geom_tbl inner_t
    WHERE inner_t.id = outer_t.id
      AND inner_t.geom.STIntersects(
          geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1
)
AND outer_t.geom IS NOT NULL;
GO

-- ============================================================
-- SECTION 30: COLUMN-TO-COLUMN PREDICATE
-- ============================================================

-- 30.1 Self-join using column-to-column STIntersects
SELECT COUNT(*) AS t30_col_col FROM si_geom_tbl a
INNER JOIN si_geom_tbl b ON a.geom.STIntersects(b.geom) = 1
WHERE a.id <= 5 AND b.id <= 5;
GO

-- 30.2 Column-to-column STDistance predicate
SELECT COUNT(*) AS t30_dist_col FROM si_geom_tbl a
INNER JOIN si_geom_tbl b ON a.geom.STDistance(b.geom) < 10
WHERE a.id <= 10 AND b.id <= 10 AND a.id <> b.id;
GO

-- ============================================================
-- SECTION 31: ORDER BY SPATIAL DISTANCE (nearest-neighbor)
-- ============================================================

-- 31.1 ORDER BY STDistance (should not inject bbox)
SELECT TOP 3 id
FROM si_geom_tbl
WHERE si_geom_tbl.geom IS NOT NULL
ORDER BY si_geom_tbl.geom.STDistance(
    geometry::STGeomFromText('POINT(500 500)', 4326)), id;
GO

-- ============================================================
-- SECTION 32: TOP N WITH SPATIAL FILTER
-- ============================================================

-- 32.1 TOP N with pure spatial WHERE + deterministic ORDER BY
SELECT TOP 5 id FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 300 100, 300 300, 100 300, 100 100))', 4326)) = 1
ORDER BY id;
GO

-- ============================================================
-- SECTION 33: sp_executesql (parameterized pattern via server-side prepare)
-- ============================================================

-- 33.1 sp_executesql with @poly parameter bound at execution
DECLARE @sql NVARCHAR(1000) =
    N'SELECT COUNT(*) AS t33_sp FROM si_geom_tbl WHERE si_geom_tbl.geom.STIntersects(@p) = 1';
DECLARE @poly sys.GEOMETRY = geometry::STGeomFromText(
    'POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326);
EXEC sp_executesql @sql, N'@p sys.GEOMETRY', @p = @poly;
GO

-- ============================================================
-- SECTION 34: ALTER TABLE INTERACTIONS
-- ============================================================

-- 34.1 ADD an unrelated column to a table with a spatial index; index should survive
ALTER TABLE si_ddl_tbl ADD extra_col INT NULL;
GO

-- 34.2 DROP the column and verify spatial index still usable
ALTER TABLE si_ddl_tbl DROP COLUMN extra_col;
GO

-- 34.3 Spatial index still functions after ALTER
CREATE SPATIAL INDEX si_after_alter ON si_ddl_tbl(geom);
GO
DROP INDEX si_after_alter ON si_ddl_tbl;
GO

-- ============================================================
-- SECTION 35: ERROR PATH — non-existent table
-- ============================================================

-- 35.1 CREATE SPATIAL INDEX on table that does not exist
CREATE SPATIAL INDEX si_no_table ON no_such_table(geom);
GO

-- ============================================================
-- SECTION 36: MULTI-GEOMETRY TYPES
-- ============================================================
SELECT set_config('enable_seqscan', 'off', false)
SELECT set_config('enable_bitmapscan', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO

SELECT COUNT(*) AS t36_mpoint FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
GO


SELECT COUNT(*) AS t36_mpoly FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((115 115, 145 115, 145 145, 115 145, 115 115))', 4326)) = 1;
GO

-- Section 38: STDistance RHS non-literal forms
-- 38.1 Column as threshold
ALTER TABLE si_geom_tbl ADD thr FLOAT NULL;
GO
UPDATE si_geom_tbl SET thr = 100 WHERE id <= 500;
UPDATE si_geom_tbl SET thr = 50  WHERE id > 500;
GO

SELECT COUNT(*) AS t38_col_rhs FROM si_geom_tbl
WHERE si_geom_tbl.thr IS NOT NULL
  AND si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326)) < si_geom_tbl.thr;
GO
-- Expected: some positive int (run seq-scan version first to capture)

-- 38.2 Arithmetic RHS
DECLARE @f FLOAT = 50;
SELECT COUNT(*) AS t38_arith FROM si_geom_tbl
WHERE si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326)) < (2 * @f);
GO
-- Expected: should match `< 100` = 35

-- 38.3 Cleanup
ALTER TABLE si_geom_tbl DROP COLUMN thr;
GO


-- Section 39: Chained spatial methods
SELECT COUNT(*) AS t39_chain FROM si_geom_tbl
WHERE si_geom_tbl.geom.MakeValid().STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
GO
-- Expected: should either work (count = 13) or produce a clean error
-- Must NOT produce invalid SQL

-- Section 40: Two STIntersects on same column in one predicate
SELECT COUNT(*) AS t40_two_spatial FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(geometry::STGeomFromText('POLYGON((100 100, 300 100, 300 300, 100 300, 100 100))', 4326)) = 1
  AND si_geom_tbl.geom.STIntersects(geometry::STGeomFromText('POLYGON((150 150, 250 150, 250 250, 150 250, 150 150))', 4326)) = 1;
GO
-- Expected: some int >= 0, both predicates should rewrite independently

-- Section 41: Schema-qualified column in predicate
SELECT COUNT(*) AS t41_schema FROM master_dbo.si_geom_tbl
WHERE master_dbo.si_geom_tbl.geom.STIntersects(
    geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) = 1;
GO
-- Expected: 13 (same as unqualified). Catches col_ref extraction assuming 2-part name.

-- Section 42: Stress — large WKT polygon
SELECT COUNT(*) AS t42_large_wkt FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(geometry::STGeomFromText(
  'POLYGON((100 100, 110 100, 120 100, 130 100, 140 100, 150 100, 160 100, 170 100, 180 100, 190 100, 200 100, 200 110, 200 120, 200 130, 200 140, 200 150, 200 160, 200 170, 200 180, 200 190, 200 200, 190 200, 180 200, 170 200, 160 200, 150 200, 140 200, 130 200, 120 200, 110 200, 100 200, 100 190, 100 180, 100 170, 100 160, 100 150, 100 140, 100 130, 100 120, 100 110, 100 100))',
  4326)) = 1;
GO
-- Expected: 13 (same as simple 4-vertex polygon covering same area)


-- Section 43: Spatial call as GROUP BY key (no injection expected — aggregate context)
SET BABELFISH_STATISTICS PROFILE OFF;
GO
SELECT t43_hit = CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
  SELECT si_geom_tbl.geom.STIntersects(geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326)) AS hit,
         COUNT(*) AS c
  FROM si_geom_tbl
  GROUP BY si_geom_tbl.geom.STIntersects(geometry::STGeomFromText('POLYGON((100 100, 200 100, 200 200, 100 200, 100 100))', 4326))
) sub
WHERE hit = 1;
GO
-- Expected: PASS. Confirms rewriter doesn't inject where it shouldn't.

-- to their declared default (EH_STRICT).

-- 44.1 Confirm the non-default value set by vu-prepare is currently active
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_spatial_index';
GO

-- 44.2 Trigger a TDS connection reset
EXEC sys.sp_reset_connection;
GO

-- 44.3 Confirm the GUC reverted to its declared default ('strict')
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_spatial_index';
GO

-- 44.4 Restore the non-default value so the cleanup file runs in the expected state
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_spatial_index', 'ignore';
GO


-- ============================================================
-- SECTION 46: SELF-INTERSECTION (PR-claimed guard)
-- ============================================================

-- 46.1 col.STIntersects(col) = 1 — degenerate self-intersection.
-- Equivalence check: the dot-method form must produce the same count as the
-- explicit two-arg form, regardless of which plan path is taken.
DECLARE @dot INT, @explicit INT;
SELECT @dot = COUNT(*) FROM si_geom_tbl
WHERE si_geom_tbl.geom.STIntersects(si_geom_tbl.geom) = 1;
SELECT @explicit = COUNT(*) FROM si_geom_tbl a INNER JOIN si_geom_tbl b ON a.id = b.id
WHERE a.geom.STIntersects(b.geom) = 1;
SELECT CASE WHEN @dot = @explicit THEN 'PASS' ELSE 'FAIL' END AS t46_self_intersect;
GO

-- ============================================================
-- SECTION 47: COMPOUND @VARIABLE THRESHOLD IN STDistance
-- ============================================================

-- 47.1 STDistance(...) < @r + 10 — compound expression must not break
-- the rewriter (previously the @-prefix quoting would emit "@r + 10" as
-- a malformed identifier and fail at execution time).
DECLARE @r FLOAT = 100;
DECLARE @cnt_compound INT, @cnt_literal INT;
SELECT @cnt_compound = COUNT(*) FROM si_geom_tbl
WHERE si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326)) < @r + 10;
SELECT @cnt_literal = COUNT(*) FROM si_geom_tbl
WHERE si_geom_tbl.geom.STDistance(geometry::STGeomFromText('POINT(500 500)', 4326)) < 110;
SELECT CASE WHEN @cnt_compound = @cnt_literal THEN 'PASS' ELSE 'FAIL' END AS t47_compound_threshold;
GO


-- ============================================================
-- SECTION 45: sys.spatial_indexes multi-database isolation
-- ============================================================
-- 45.1 From si_multidb_a_ : only sidx_multi_a_ is visible
USE si_multidb_a_;
GO

SELECT name AS t45_idx_in_a
FROM sys.spatial_indexes
WHERE name LIKE 'sidx_multi%'
ORDER BY name;
GO

-- 45.2 From si_multidb_a_ : sidx_multi_b_ must NOT be visible
SELECT COUNT(*) AS t45_b_leak_from_a
FROM sys.spatial_indexes
WHERE name = 'sidx_multi_b_';
GO

-- 45.3 From si_multidb_b_ : only sidx_multi_b_ is visible
USE si_multidb_b_;
GO

SELECT name AS t45_idx_in_b
FROM sys.spatial_indexes
WHERE name LIKE 'sidx_multi%'
ORDER BY name;
GO

-- 45.4 From si_multidb_b_ : sidx_multi_a_ must NOT be visible
SELECT COUNT(*) AS t45_a_leak_from_b
FROM sys.spatial_indexes
WHERE name = 'sidx_multi_a_';
GO

-- 45.5 From master : neither cross-db spatial index is visible here
USE master;
GO

SELECT COUNT(*) AS t45_master_leak
FROM sys.spatial_indexes
WHERE name IN ('sidx_multi_a_', 'sidx_multi_b_');
GO


