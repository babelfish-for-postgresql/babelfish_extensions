-- sla 80000
-- ============================================================================
-- SECTION 1: MultiPoint 2D (XY) — Text Input
-- ============================================================================
-- TC-MP-001: MultiPoint 2D — 2 Points
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326);
GO

-- TC-MP-001: Roundtrip
SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-002: MultiPoint 2D — 3 Points
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4), (5 6))', 4326);
GO

-- TC-MP-002: Roundtrip
SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2), (3 4), (5 6))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-003: MultiPoint 2D — 4 Points
SELECT geometry::STGeomFromText('MULTIPOINT((0 0), (1 1), (2 2), (3 3))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((0 0), (1 1), (2 2), (3 3))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-004: MultiPoint 2D — 5 Points
SELECT geometry::STGeomFromText('MULTIPOINT((0 0), (10 0), (10 10), (0 10), (5 5))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((0 0), (10 0), (10 10), (0 10), (5 5))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-005: MultiPoint 2D — 7 Points
SELECT geometry::STGeomFromText('MULTIPOINT((0 0), (2 3), (4 5), (6 4), (4 2), (2 1), (1 1))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((0 0), (2 3), (4 5), (6 4), (4 2), (2 1), (1 1))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-006: MultiPoint 2D — 10 Points
SELECT geometry::STGeomFromText('MULTIPOINT((0 0),(1 1),(2 2),(3 3),(4 4),(5 5),(6 6),(7 7),(8 8),(9 9))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((0 0),(1 1),(2 2),(3 3),(4 4),(5 5),(6 6),(7 7),(8 8),(9 9))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-007: MultiPoint 2D — Single Point
SELECT geometry::STGeomFromText('MULTIPOINT((1 2))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-008: MultiPoint 2D — Negative Coordinates
SELECT geometry::STGeomFromText('MULTIPOINT((-1 -2), (-3 -4))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((-1 -2), (-3 -4))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-009: MultiPoint 2D — Mixed Positive/Negative
SELECT geometry::STGeomFromText('MULTIPOINT((-1 2), (3 -4), (0 0))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((-1 2), (3 -4), (0 0))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-010: MultiPoint 2D — Decimal Coordinates
SELECT geometry::STGeomFromText('MULTIPOINT((1.5 2.7), (3.14159 4.00001))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1.5 2.7), (3.14159 4.00001))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-011: MultiPoint 2D — Very Large Coordinates
SELECT geometry::STGeomFromText('MULTIPOINT((999999999 999999999), (-999999999 -999999999))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((999999999 999999999), (-999999999 -999999999))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-012: MultiPoint 2D — Very Small Coordinates
SELECT geometry::STGeomFromText('MULTIPOINT((0.000001 0.000001), (0.000002 0.000002))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((0.000001 0.000001), (0.000002 0.000002))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-013: MultiPoint 2D — Zero Coordinates
SELECT geometry::STGeomFromText('MULTIPOINT((0 0), (0 0))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((0 0), (0 0))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-014: MultiPoint 2D — Duplicate Points (2 same)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (1 2))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2), (1 2))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-015: MultiPoint 2D — 3 Identical Points
SELECT geometry::STGeomFromText('MULTIPOINT((5 5), (5 5), (5 5))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((5 5), (5 5), (5 5))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-016: MultiPoint 2D — Alternate WKT (no inner parens)
SELECT geometry::STGeomFromText('MULTIPOINT(1 2, 3 4)', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT(1 2, 3 4)', 4326) AS varbinary(max)) AS geometry);
GO


-- ============================================================================
-- SECTION 2: MultiPoint 3D (XYZ) — Text Input
-- ============================================================================

-- TC-MP-017: MultiPoint 3D — 2 Points
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3), (4 5 6))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 3), (4 5 6))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-018: MultiPoint 3D — 3 Points
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3), (4 5 6), (7 8 9))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 3), (4 5 6), (7 8 9))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-019: MultiPoint 3D — Single Point
SELECT geometry::STGeomFromText('MULTIPOINT((10 20 30))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((10 20 30))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-020: MultiPoint 3D — 5 Points
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3), (4 5 6), (7 8 9), (10 11 12), (13 14 15))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 3), (4 5 6), (7 8 9), (10 11 12), (13 14 15))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-021: MultiPoint 3D — Negative Z
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 -3), (4 5 -6))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 -3), (4 5 -6))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-022: MultiPoint 3D — Zero Z
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 0), (4 5 0))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 0), (4 5 0))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-023: MultiPoint 3D — Partial Z (first has Z, second doesn't)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3), (4 5))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 3), (4 5))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-024: MultiPoint 3D — Partial Z (first doesn't, second has Z)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (4 5 6))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2), (4 5 6))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-025: MultiPoint 3D — Partial Z (middle missing, 3 points)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3), (4 5), (7 8 9))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 3), (4 5), (7 8 9))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-026: MultiPoint 3D — Decimal Z values
SELECT geometry::STGeomFromText('MULTIPOINT((1.1 2.2 3.3), (4.4 5.5 6.6))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1.1 2.2 3.3), (4.4 5.5 6.6))', 4326) AS varbinary(max)) AS geometry);
GO


-- ============================================================================
-- SECTION 3: MultiPoint 2DM (XYM) — Text Input
-- ============================================================================

-- TC-MP-027: MultiPoint 2DM — 2 Points (Full M)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 NULL 4), (5 6 NULL 8))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 NULL 4), (5 6 NULL 8))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-028: MultiPoint 2DM — 3 Points (Full M)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 NULL 10), (3 4 NULL 20), (5 6 NULL 30))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 NULL 10), (3 4 NULL 20), (5 6 NULL 30))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-029: MultiPoint 2DM — Single Point
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 NULL 4))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 NULL 4))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-030: MultiPoint 2DM — Partial M (first has M, second doesn't)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 NULL 4), (5 6))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 NULL 4), (5 6))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-031: MultiPoint 2DM — Partial M (first doesn't, second has M)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (5 6 NULL 8))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2), (5 6 NULL 8))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-032: MultiPoint 2DM — Partial M (middle missing, 3 points)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 NULL 4), (5 6), (7 8 NULL 10))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 NULL 4), (5 6), (7 8 NULL 10))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-033: MultiPoint 2DM — Negative M values
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 NULL -4), (5 6 NULL -8))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 NULL -4), (5 6 NULL -8))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-034: MultiPoint 2DM — Zero M values
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 NULL 0), (5 6 NULL 0))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 NULL 0), (5 6 NULL 0))', 4326) AS varbinary(max)) AS geometry);
GO


-- ============================================================================
-- SECTION 4: MultiPoint 4D (XYZM) — Text Input
-- ============================================================================

-- TC-MP-035: MultiPoint 4D — 2 Points (Full XYZM)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3 4), (5 6 7 8))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 3 4), (5 6 7 8))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-036: MultiPoint 4D — 3 Points (Full XYZM)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3 4), (5 6 7 8), (9 10 11 12))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 3 4), (5 6 7 8), (9 10 11 12))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-037: MultiPoint 4D — Single Point
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3 4))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 3 4))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-038: MultiPoint 4D — 5 Points
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3 4), (5 6 7 8), (9 10 11 12), (13 14 15 16), (17 18 19 20))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 3 4), (5 6 7 8), (9 10 11 12), (13 14 15 16), (17 18 19 20))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-039: MultiPoint 4D — Partial (Z on some, M on some)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3 4), (5 6 7), (8 9))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 3 4), (5 6 7), (8 9))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-040: MultiPoint 4D — First has Z only, second has ZM
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3), (5 6 7 8))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 3), (5 6 7 8))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-041: MultiPoint 4D — First has M only, second has ZM
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 NULL 4), (5 6 7 8))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 NULL 4), (5 6 7 8))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-042: MultiPoint 4D — All partial (no point has full dims)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3), (5 6 NULL 8), (9 10))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 3), (5 6 NULL 8), (9 10))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-043: MultiPoint 4D — Negative Z and M
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 -3 -4), (5 6 -7 -8))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2 -3 -4), (5 6 -7 -8))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-044: MultiPoint 4D — Decimal Z and M
SELECT geometry::STGeomFromText('MULTIPOINT((1.1 2.2 3.3 4.4), (5.5 6.6 7.7 8.8))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1.1 2.2 3.3 4.4), (5.5 6.6 7.7 8.8))', 4326) AS varbinary(max)) AS geometry);
GO


-- ============================================================================
-- SECTION 5: MultiPoint EMPTY
-- ============================================================================

-- TC-MP-045: MultiPoint EMPTY — SRID 4326
SELECT geometry::STGeomFromText('MULTIPOINT EMPTY', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT EMPTY', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-046: MultiPoint EMPTY — SRID 0
SELECT geometry::STGeomFromText('MULTIPOINT EMPTY', 0);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT EMPTY', 0) AS varbinary(max)) AS geometry);
GO


-- ============================================================================
-- SECTION 6: MultiPoint — SRID Variations
-- ============================================================================

-- TC-MP-048: SRID 0
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 0);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 0) AS varbinary(max)) AS geometry);
GO

-- TC-MP-049: SRID 4326
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-050: SRID 4269
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4269);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4269) AS varbinary(max)) AS geometry);
GO

-- TC-MP-051: SRID 3857
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 3857);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 3857) AS varbinary(max)) AS geometry);
GO

-- TC-MP-052: Large SRID (999999)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 999999);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 999999) AS varbinary(max)) AS geometry);
GO

-- TC-MP-053: SRID 1 (minimum non-zero)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 1);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 1) AS varbinary(max)) AS geometry);
GO

-- TC-MP-054: SRID Out of Range — Negative (should ERROR)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', -1);
GO

-- TC-MP-055: SRID Out of Range — Too Large (should ERROR)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 1000000);
GO

-- TC-MP-056: SRID Out of Range — Very Large (should ERROR)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 99999999);
GO


-- ============================================================================
-- SECTION 7: MultiPoint — STAsText Output
-- ============================================================================

-- TC-MP-057: STAsText — 2D, 2 Points
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STAsText();
GO

-- TC-MP-058: STAsText — 2D, 3 Points
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4), (5 6))', 4326).STAsText();
GO

-- TC-MP-059: STAsText — 2D, Single Point
SELECT geometry::STGeomFromText('MULTIPOINT((42 84))', 4326).STAsText();
GO

-- TC-MP-060: STAsText — 3D (Z stripped)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3), (4 5 6))', 4326).STAsText();
GO

-- TC-MP-061: STAsText — 4D (ZM stripped)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3 4), (5 6 7 8))', 4326).STAsText();
GO

-- TC-MP-062: STAsText — 2DM (M stripped)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 NULL 4), (5 6 NULL 8))', 4326).STAsText();
GO

-- TC-MP-063: STAsText — Empty
SELECT geometry::STGeomFromText('MULTIPOINT EMPTY', 4326).STAsText();
GO

-- TC-MP-064: STAsText — Decimal Coordinates
SELECT geometry::STGeomFromText('MULTIPOINT((1.5 2.7), (3.14159 4.00001))', 4326).STAsText();
GO

-- TC-MP-065: STAsText — Negative Coordinates
SELECT geometry::STGeomFromText('MULTIPOINT((-1 -2), (-3 -4))', 4326).STAsText();
GO

-- TC-MP-066: STAsText — Large Coordinates
SELECT geometry::STGeomFromText('MULTIPOINT((999999999 999999999), (-999999999 -999999999))', 4326).STAsText();
GO


-- ============================================================================
-- SECTION 8: MultiPoint — STAsBinary Output
-- ============================================================================

-- TC-MP-067: STAsBinary — 2D, 2 Points
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STAsBinary();
GO

-- TC-MP-068: STAsBinary — 2D, 3 Points
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4), (5 6))', 4326).STAsBinary();
GO

-- TC-MP-069: STAsBinary — 3D (Z stripped in WKB)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3), (4 5 6))', 4326).STAsBinary();
GO

-- TC-MP-070: STAsBinary — 4D (ZM stripped in WKB)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3 4), (5 6 7 8))', 4326).STAsBinary();
GO

-- TC-MP-071: STAsBinary — Empty
SELECT geometry::STGeomFromText('MULTIPOINT EMPTY', 4326).STAsBinary();
GO

-- TC-MP-072: STAsBinary — Single Point
SELECT geometry::STGeomFromText('MULTIPOINT((42 84))', 4326).STAsBinary();
GO


-- ============================================================================
-- SECTION 9: MultiPoint — CAST to/from VARCHAR
-- ============================================================================

-- TC-MP-073: CAST geometry to VARCHAR(MAX)
SELECT CAST(geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326) AS VARCHAR(MAX));
GO

-- TC-MP-074: CAST geometry to NVARCHAR(MAX)
SELECT CAST(geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326) AS NVARCHAR(MAX));
GO

-- TC-MP-075: CAST geometry to VARCHAR(100) — enough room
SELECT CAST(geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326) AS VARCHAR(100));
GO

-- TC-MP-076: CAST geometry to VARCHAR(5) — truncation
SELECT CAST(geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326) AS VARCHAR(5));
GO

-- TC-MP-077: CAST VARCHAR to geometry
SELECT CAST('MULTIPOINT((1 2), (3 4))' AS geometry);
GO

-- TC-MP-078: CAST NVARCHAR to geometry
SELECT CAST(N'MULTIPOINT((1 2), (3 4))' AS geometry);
GO

-- TC-MP-079: CAST empty MultiPoint string to geometry
SELECT CAST('MULTIPOINT EMPTY' AS geometry);
GO

-- TC-MP-080: CAST 3D MultiPoint string to geometry
SELECT CAST('MULTIPOINT((1 2 3), (4 5 6))' AS geometry);
GO

-- TC-MP-081: CAST 4D MultiPoint string to geometry
SELECT CAST('MULTIPOINT((1 2 3 4), (5 6 7 8))' AS geometry);
GO

-- TC-MP-082: Implicit conversion via variable assignment
DECLARE @g geometry = 'MULTIPOINT((1 2), (3 4))';
SELECT CAST(@g AS varbinary(max));
GO


-- ============================================================================
-- SECTION 10: MultiPoint — CAST to/from VARBINARY
-- ============================================================================

-- TC-MP-083: CAST geometry to VARBINARY(MAX)
SELECT CAST(geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326) AS VARBINARY(MAX));
GO

-- TC-MP-084: CAST VARBINARY back to geometry — 2D
DECLARE @g084 geometry = geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326);
DECLARE @bin084 VARBINARY(MAX) = CAST(@g084 AS VARBINARY(MAX));
SELECT CAST(@bin084 AS geometry).STAsText();
GO

-- TC-MP-085: CAST VARBINARY back to geometry — 3D
DECLARE @g085 geometry = geometry::STGeomFromText('MULTIPOINT((1 2 3), (4 5 6))', 4326);
DECLARE @bin085 VARBINARY(MAX) = CAST(@g085 AS VARBINARY(MAX));
SELECT CAST(@bin085 AS geometry).STAsText();
GO

-- TC-MP-086: CAST VARBINARY back to geometry — 4D
DECLARE @g086 geometry = geometry::STGeomFromText('MULTIPOINT((1 2 3 4), (5 6 7 8))', 4326);
DECLARE @bin086 VARBINARY(MAX) = CAST(@g086 AS VARBINARY(MAX));
SELECT CAST(@bin086 AS geometry).STAsText();
GO

-- TC-MP-087: CAST VARBINARY back to geometry — Empty
DECLARE @g087 geometry = geometry::STGeomFromText('MULTIPOINT EMPTY', 4326);
DECLARE @bin087 VARBINARY(MAX) = CAST(@g087 AS VARBINARY(MAX));
SELECT CAST(@bin087 AS geometry).STAsText();
GO


-- TC-MP-088: CAST to VARBINARY(1) — truncation
DECLARE @g088 geometry = geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326);
SELECT CAST(@g088 AS VARBINARY(1));
GO


-- ============================================================================
-- SECTION 11: MultiPoint — Full Round-Trip Chains
-- ============================================================================

-- TC-MP-089: WKT → geometry → VARBINARY → geometry → WKT (2D)
DECLARE @wkt089 VARCHAR(MAX) = 'MULTIPOINT((1 2), (3 4), (5 6))';
DECLARE @g089a geometry = geometry::STGeomFromText(@wkt089, 4326);
DECLARE @bin089 VARBINARY(MAX) = CAST(@g089a AS VARBINARY(MAX));
DECLARE @g089b geometry = CAST(@bin089 AS geometry);
SELECT @g089b.STAsText();
GO

-- TC-MP-090: WKT → geometry → WKB → geometry → WKT (2D)
DECLARE @wkt090 VARCHAR(MAX) = 'MULTIPOINT((1 2), (3 4))';
DECLARE @g090a geometry = geometry::STGeomFromText(@wkt090, 4326);
DECLARE @wkb090 VARBINARY(MAX) = @g090a.STAsBinary();
DECLARE @g090b geometry = geometry::STGeomFromWKB(@wkb090, 4326);
SELECT @g090b.STAsText();
GO

-- TC-MP-091: Double round-trip WKT → geom → WKT → geom → WKT
DECLARE @wkt091a VARCHAR(MAX) = 'MULTIPOINT((1.5 2.5), (3.5 4.5))';
DECLARE @g091a geometry = geometry::STGeomFromText(@wkt091a, 4326);
DECLARE @wkt091b VARCHAR(MAX) = @g091a.STAsText();
DECLARE @g091b geometry = geometry::STGeomFromText(@wkt091b, 4326);
DECLARE @wkt091c VARCHAR(MAX) = @g091b.STAsText();
SELECT @wkt091b, @wkt091c;
GO


-- TC-MP-092: Double round-trip VARBINARY → geom → VARBINARY → geom → VARBINARY
DECLARE @g092a geometry = geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326);
DECLARE @bin092a VARBINARY(MAX) = CAST(@g092a AS VARBINARY(MAX));
DECLARE @g092b geometry = CAST(@bin092a AS geometry);
DECLARE @bin092b VARBINARY(MAX) = CAST(@g092b AS VARBINARY(MAX));
DECLARE @g092c geometry = CAST(@bin092b AS geometry);
DECLARE @bin092c VARBINARY(MAX) = CAST(@g092c AS VARBINARY(MAX));
SELECT @bin092a, @bin092b, @bin092c;
GO

-- TC-MP-093: WKT → geom → VARBINARY → geom → WKB → geom → WKT
DECLARE @wkt093 VARCHAR(MAX) = 'MULTIPOINT((10 20), (30 40))';
DECLARE @g093a geometry = geometry::STGeomFromText(@wkt093, 4326);
DECLARE @bin093 VARBINARY(MAX) = CAST(@g093a AS VARBINARY(MAX));
DECLARE @g093b geometry = CAST(@bin093 AS geometry);
DECLARE @wkb093 VARBINARY(MAX) = @g093b.STAsBinary();
DECLARE @g093c geometry = geometry::STGeomFromWKB(@wkb093, 4326);
SELECT @g093c.STAsText();
GO

-- TC-MP-094: Round-trip 3D — Verify Z preserved through internal binary
DECLARE @g094a geometry = geometry::STGeomFromText('MULTIPOINT((1 2 3), (4 5 6))', 4326);
DECLARE @bin094 VARBINARY(MAX) = CAST(@g094a AS VARBINARY(MAX));
DECLARE @g094b geometry = CAST(@bin094 AS geometry);
DECLARE @bin094b VARBINARY(MAX) = CAST(@g094b AS VARBINARY(MAX));
SELECT @bin094, @bin094b;
GO

-- TC-MP-095: Round-trip 4D — Verify ZM preserved through internal binary
DECLARE @g095a geometry = geometry::STGeomFromText('MULTIPOINT((1 2 3 4), (5 6 7 8))', 4326);
DECLARE @bin095 VARBINARY(MAX) = CAST(@g095a AS VARBINARY(MAX));
DECLARE @g095b geometry = CAST(@bin095 AS geometry);
DECLARE @bin095b VARBINARY(MAX) = CAST(@g095b AS VARBINARY(MAX));
SELECT @bin095, @bin095b;
GO

-- TC-MP-096: Round-trip Empty
DECLARE @g096a geometry = geometry::STGeomFromText('MULTIPOINT EMPTY', 4326);
DECLARE @bin096 VARBINARY(MAX) = CAST(@g096a AS VARBINARY(MAX));
DECLARE @g096b geometry = CAST(@bin096 AS geometry);
SELECT @g096b.STAsText();
GO

-- TC-MP-097: Round-trip — SRID preservation
DECLARE @g097a geometry = geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326);
DECLARE @bin097 VARBINARY(MAX) = CAST(@g097a AS VARBINARY(MAX));
DECLARE @g097b geometry = CAST(@bin097 AS geometry);
SELECT @g097a.STSrid, @g097b.STSrid;
GO

-- TC-MP-098: Round-trip — SRID 0 preservation
DECLARE @g098a geometry = geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 0);
DECLARE @bin098 VARBINARY(MAX) = CAST(@g098a AS VARBINARY(MAX));
DECLARE @g098b geometry = CAST(@bin098 AS geometry);
SELECT @g098a.STSrid, @g098b.STSrid;
GO


-- ============================================================================
-- SECTION 12: MultiPoint — STMPointFromText / STMPointFromWKB
-- ============================================================================

-- TC-MP-099: STMPointFromText — Basic 2D
SELECT geometry::STMPointFromText('MULTIPOINT((1 2), (3 4))', 4326);
GO

SELECT CAST(CAST(geometry::STMPointFromText('MULTIPOINT((1 2), (3 4))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-100: STMPointFromText — 3D
SELECT geometry::STMPointFromText('MULTIPOINT((1 2 3), (4 5 6))', 4326);
GO

SELECT CAST(CAST(geometry::STMPointFromText('MULTIPOINT((1 2 3), (4 5 6))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-101: STMPointFromText — 4D
SELECT geometry::STMPointFromText('MULTIPOINT((1 2 3 4), (5 6 7 8))', 4326);
GO

SELECT CAST(CAST(geometry::STMPointFromText('MULTIPOINT((1 2 3 4), (5 6 7 8))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-102: STMPointFromText — Empty
SELECT geometry::STMPointFromText('MULTIPOINT EMPTY', 4326);
GO

SELECT CAST(CAST(geometry::STMPointFromText('MULTIPOINT EMPTY', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-103: STMPointFromText — Wrong geometry type LINESTRING (should ERROR)
SELECT geometry::STMPointFromText('LINESTRING(1 2, 3 4)', 4326);
GO

-- TC-MP-104: STMPointFromText — Wrong geometry type POINT (should ERROR)
SELECT geometry::STMPointFromText('POINT(1 2)', 4326);
GO

-- TC-MP-105: STMPointFromText — Wrong geometry type POLYGON (should ERROR)
SELECT geometry::STMPointFromText('POLYGON((0 0, 1 0, 1 1, 0 0))', 4326);
GO

-- TC-MP-106: STMPointFromText — NULL input
SELECT geometry::STMPointFromText(NULL, 4326);
GO

-- TC-MP-107: STMPointFromWKB — Basic
DECLARE @wkb107 VARBINARY(MAX) = geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STAsBinary();
SELECT geometry::STMPointFromWKB(@wkb107, 4326).STAsText();
GO

-- TC-MP-108: STMPointFromWKB — Wrong type binary (should ERROR)
DECLARE @wkb108 VARBINARY(MAX) = geometry::STGeomFromText('LINESTRING(1 2, 3 4)', 4326).STAsBinary();
SELECT geometry::STMPointFromWKB(@wkb108, 4326);
GO

-- TC-MP-109: STMPointFromWKB — NULL
SELECT geometry::STMPointFromWKB(NULL, 4326);
GO


-- ============================================================================
-- SECTION 13: MultiPoint — Parse / Direct Assignment
-- ============================================================================

-- TC-MP-110: geometry::Parse — 2D
SELECT geometry::Parse('MULTIPOINT((1 2), (3 4))');
GO

SELECT CAST(CAST(geometry::Parse('MULTIPOINT((1 2), (3 4))') AS varbinary(max)) AS geometry);
GO

-- TC-MP-111: geometry::Parse — 3D
SELECT geometry::Parse('MULTIPOINT((1 2 3), (4 5 6))');
GO

SELECT CAST(CAST(geometry::Parse('MULTIPOINT((1 2 3), (4 5 6))') AS varbinary(max)) AS geometry);
GO

-- TC-MP-112: geometry::Parse — 4D
SELECT geometry::Parse('MULTIPOINT((1 2 3 4), (5 6 7 8))');
GO

-- TC-MP-113: geometry::Parse — Empty
SELECT geometry::Parse('MULTIPOINT EMPTY');
GO

SELECT CAST(CAST(geometry::Parse('MULTIPOINT EMPTY') AS varbinary(max)) AS geometry);
GO

-- TC-MP-114: Direct string assignment to variable
DECLARE @g114 geometry;
SET @g114 = 'MULTIPOINT((1 2), (3 4))';
SELECT @g114.STAsText();
SELECT CAST(@g114 AS varbinary(max));
GO


-- ============================================================================
-- SECTION 14: MultiPoint — STGeomFromWKB
-- ============================================================================

-- TC-MP-115: STGeomFromWKB — 2D
DECLARE @wkb115 VARBINARY(MAX) = geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STAsBinary();
SELECT geometry::STGeomFromWKB(@wkb115, 4326).STAsText();
GO

-- TC-MP-116: STGeomFromWKB — 3D (note: WKB is 2D, Z lost)
DECLARE @g116 geometry = geometry::STGeomFromText('MULTIPOINT((1 2 3), (4 5 6))', 4326);
DECLARE @wkb116 VARBINARY(MAX) = @g116.STAsBinary();
SELECT geometry::STGeomFromWKB(@wkb116, 4326).STAsText();
GO

-- TC-MP-117: STGeomFromWKB — Empty
DECLARE @wkb117 VARBINARY(MAX) = geometry::STGeomFromText('MULTIPOINT EMPTY', 4326).STAsBinary();
SELECT geometry::STGeomFromWKB(@wkb117, 4326).STAsText();
GO

-- TC-MP-118: STGeomFromWKB — NULL
SELECT geometry::STGeomFromWKB(NULL, 4326);
GO

-- TC-MP-119: STGeomFromWKB — SRID preservation
DECLARE @wkb119 VARBINARY(MAX) = geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STAsBinary();
SELECT geometry::STGeomFromWKB(@wkb119, 4326).STSrid;
GO

-- TC-MP-120: STGeomFromWKB — Different SRID
DECLARE @wkb120 VARBINARY(MAX) = geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STAsBinary();
SELECT geometry::STGeomFromWKB(@wkb120, 0).STSrid;
GO


-- ============================================================================
-- SECTION 15: MultiPoint — Case Insensitivity in WKT
-- ============================================================================

-- TC-MP-121: lowercase
SELECT geometry::STGeomFromText('multipoint((1 2), (3 4))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('multipoint((1 2), (3 4))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-122: UPPERCASE
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326);
GO

-- TC-MP-123: MixedCase
SELECT geometry::STGeomFromText('Multipoint((1 2), (3 4))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('Multipoint((1 2), (3 4))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-124: Random case
SELECT geometry::STGeomFromText('MuLtIpOiNt((1 2), (3 4))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MuLtIpOiNt((1 2), (3 4))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-125: Verify all cases produce same binary
DECLARE @bin_lower VARBINARY(MAX) = CAST(geometry::STGeomFromText('multipoint((1 2), (3 4))', 4326) AS VARBINARY(MAX));
DECLARE @bin_upper VARBINARY(MAX) = CAST(geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326) AS VARBINARY(MAX));
DECLARE @bin_mixed VARBINARY(MAX) = CAST(geometry::STGeomFromText('Multipoint((1 2), (3 4))', 4326) AS VARBINARY(MAX));
SELECT @bin_lower, @bin_upper, @bin_mixed;
GO


-- ============================================================================
-- SECTION 16: MultiPoint — Whitespace Handling in WKT
-- ============================================================================

-- TC-MP-126: Extra whitespace everywhere
SELECT geometry::STGeomFromText('  MULTIPOINT  (  ( 1  2 ) ,  ( 3  4 )  )  ', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('  MULTIPOINT  (  ( 1  2 ) ,  ( 3  4 )  )  ', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-127: Tab characters
SELECT geometry::STGeomFromText('MULTIPOINT	((1	2),	(3	4))', 4326);
GO

-- TC-MP-128: Newline characters
SELECT geometry::STGeomFromText('MULTIPOINT((1 2),(3 4))', 4326);
GO

-- TC-MP-129: No spaces
SELECT geometry::STGeomFromText('MULTIPOINT((1 2),(3 4))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT((1 2),(3 4))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-130: Verify whitespace variations produce same binary
DECLARE @bin_normal VARBINARY(MAX) = CAST(geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326) AS VARBINARY(MAX));
DECLARE @bin_extra VARBINARY(MAX) = CAST(geometry::STGeomFromText('  MULTIPOINT  (  ( 1  2 ) ,  ( 3  4 )  )  ', 4326) AS VARBINARY(MAX));
DECLARE @bin_tight VARBINARY(MAX) = CAST(geometry::STGeomFromText('MULTIPOINT((1 2),(3 4))', 4326) AS VARBINARY(MAX));
SELECT @bin_normal, @bin_extra, @bin_tight;
GO


-- ============================================================================
-- SECTION 17: MultiPoint — WKT Error Cases (Negative Tests)
-- ============================================================================

-- TC-MP-131: Missing closing parenthesis
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4)', 4326);
GO

-- TC-MP-132: Missing opening parenthesis
SELECT geometry::STGeomFromText('MULTIPOINT(1 2), (3 4))', 4326);
GO

-- TC-MP-133: Extra comma at end
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4),)', 4326);
GO

-- TC-MP-134: Extra comma at beginning
SELECT geometry::STGeomFromText('MULTIPOINT(,(1 2), (3 4))', 4326);
GO

-- TC-MP-135: Double comma
SELECT geometry::STGeomFromText('MULTIPOINT((1 2),, (3 4))', 4326);
GO

-- TC-MP-136: Empty inner parentheses
SELECT geometry::STGeomFromText('MULTIPOINT(())', 4326);
GO

-- TC-MP-137: Letters in coordinates
SELECT geometry::STGeomFromText('MULTIPOINT((abc def), (3 4))', 4326);
GO

-- TC-MP-138: Only one coordinate per point
SELECT geometry::STGeomFromText('MULTIPOINT((1), (3))', 4326);
GO

-- TC-MP-139: Too many coordinates per point (5D — beyond XYZM)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3 4 5), (6 7 8 9 10))', 4326);
GO

-- TC-MP-140: NULL WKT
SELECT geometry::STGeomFromText(NULL, 4326);
GO

-- TC-MP-141: NULL SRID
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', NULL);
GO

-- TC-MP-142: Empty string WKT
SELECT geometry::STGeomFromText('', 4326);
GO

-- TC-MP-143: Typo in type name
SELECT geometry::STGeomFromText('MULTPOINT((1 2), (3 4))', 4326);
GO

-- TC-MP-144: Wrong type keyword
SELECT geometry::STGeomFromText('MULTILINESTRING((1 2), (3 4))', 4326);
GO

-- TC-MP-145: Special characters in WKT
SELECT geometry::STGeomFromText('MULTIPOINT((1 2); (3 4))', 4326);
GO

-- TC-MP-146: Completely invalid string
SELECT geometry::STGeomFromText('hello world', 4326);
GO

-- TC-MP-147: Just the keyword
SELECT geometry::STGeomFromText('MULTIPOINT', 4326);
GO

-- TC-MP-148: Empty parentheses only
SELECT geometry::STGeomFromText('MULTIPOINT()', 4326);
GO


-- ============================================================================
-- SECTION 18: MultiPoint — Geography Type
-- ============================================================================

-- TC-MP-149: Geography MultiPoint — Basic 2D, 2 Points
SELECT geography::STGeomFromText('MULTIPOINT((45 90), (50 100))', 4326);
GO

SELECT CAST(CAST(geography::STGeomFromText('MULTIPOINT((45 90), (50 100))', 4326) AS varbinary(max)) AS geography);
GO

-- TC-MP-150: Geography MultiPoint — 3 Points
SELECT geography::STGeomFromText('MULTIPOINT((0 0), (45 90), (30 60))', 4326);
GO

SELECT CAST(CAST(geography::STGeomFromText('MULTIPOINT((0 0), (45 90), (30 60))', 4326) AS varbinary(max)) AS geography);
GO

-- TC-MP-151: Geography MultiPoint — Single Point
SELECT geography::STGeomFromText('MULTIPOINT((45 90))', 4326);
GO

SELECT CAST(CAST(geography::STGeomFromText('MULTIPOINT((45 90))', 4326) AS varbinary(max)) AS geography);
GO

-- TC-MP-152: Geography MultiPoint — 5 Points
SELECT geography::STGeomFromText('MULTIPOINT((0 0), (10 20), (30 40), (50 60), (70 80))', 4326);
GO

SELECT CAST(CAST(geography::STGeomFromText('MULTIPOINT((0 0), (10 20), (30 40), (50 60), (70 80))', 4326) AS varbinary(max)) AS geography);
GO

-- TC-MP-153: Geography MultiPoint EMPTY
SELECT geography::STGeomFromText('MULTIPOINT EMPTY', 4326);
GO

SELECT CAST(CAST(geography::STGeomFromText('MULTIPOINT EMPTY', 4326) AS varbinary(max)) AS geography);
GO

-- TC-MP-154: Geography MultiPoint — 3D (Z)
SELECT geography::STGeomFromText('MULTIPOINT((45 90 100), (50 100 200))', 4326);
GO

SELECT CAST(CAST(geography::STGeomFromText('MULTIPOINT((45 90 100), (50 100 200))', 4326) AS varbinary(max)) AS geography);
GO

-- TC-MP-155: Geography MultiPoint — 4D (ZM)
SELECT geography::STGeomFromText('MULTIPOINT((45 90 100 1), (50 100 200 2))', 4326);
GO

SELECT CAST(CAST(geography::STGeomFromText('MULTIPOINT((45 90 100 1), (50 100 200 2))', 4326) AS varbinary(max)) AS geography);
GO

-- TC-MP-156: Geography MultiPoint — 2DM
SELECT geography::STGeomFromText('MULTIPOINT((45 90 NULL 1), (50 100 NULL 2))', 4326);
GO

SELECT CAST(CAST(geography::STGeomFromText('MULTIPOINT((45 90 NULL 1), (50 100 NULL 2))', 4326) AS varbinary(max)) AS geography);
GO

-- TC-MP-157: Geography MultiPoint — STAsText
SELECT geography::STGeomFromText('MULTIPOINT((45 90), (50 100))', 4326).STAsText();
GO
-- Expected: MULTIPOINT ((45 90), (50 100))

-- TC-MP-158: Geography MultiPoint — STAsBinary
SELECT geography::STGeomFromText('MULTIPOINT((45 90), (50 100))', 4326).STAsBinary();
GO

-- TC-MP-159: Geography MultiPoint — Longitude > 180 but < 15069 (valid)
SELECT geography::STGeomFromText('MULTIPOINT((181 0), (200 45))', 4326);
GO

SELECT CAST(CAST(geography::STGeomFromText('MULTIPOINT((181 0), (200 45))', 4326) AS varbinary(max)) AS geography);
GO

-- TC-MP-160: Geography MultiPoint — Boundary values
SELECT geography::STGeomFromText('MULTIPOINT((90 0), (-90 0))', 4326);
GO

SELECT CAST(CAST(geography::STGeomFromText('MULTIPOINT((90 0), (-90 0))', 4326) AS varbinary(max)) AS geography);
GO

-- TC-MP-161: Geography MultiPoint — Max longitude boundary
SELECT geography::STGeomFromText('MULTIPOINT((15069 45), (-15069 45))', 4326);
GO

SELECT CAST(CAST(geography::STGeomFromText('MULTIPOINT((15069 45), (-15069 45))', 4326) AS varbinary(max)) AS geography);
GO

-- TC-MP-162: Geography MultiPoint — Negative coordinates
SELECT geography::STGeomFromText('MULTIPOINT((-45 -90), (-50 -100))', 4326);
GO

SELECT CAST(CAST(geography::STGeomFromText('MULTIPOINT((-45 -90), (-50 -100))', 4326) AS varbinary(max)) AS geography);
GO

-- TC-MP-163: Geography MultiPoint — Zero coordinates
SELECT geography::STGeomFromText('MULTIPOINT((0 0), (0 0))', 4326);
GO

SELECT CAST(CAST(geography::STGeomFromText('MULTIPOINT((0 0), (0 0))', 4326) AS varbinary(max)) AS geography);
GO


-- ============================================================================
-- SECTION 19: Geography MultiPoint — Lat/Lon Validation (Negative Tests)
-- ============================================================================

-- TC-MP-164: Latitude overflow (>90) — first point
SELECT geography::STGeomFromText('MULTIPOINT((91 0), (1 2))', 4326);
GO

-- TC-MP-165: Latitude negative overflow (<-90) — first point
SELECT geography::STGeomFromText('MULTIPOINT((-91 0), (1 2))', 4326);
GO

-- TC-MP-166: Latitude overflow — second point
SELECT geography::STGeomFromText('MULTIPOINT((1 2), (91 0))', 4326);
GO

-- TC-MP-167: Latitude overflow — middle point (3 points)
SELECT geography::STGeomFromText('MULTIPOINT((1 2), (91 0), (3 4))', 4326);
GO

-- TC-MP-168: Latitude overflow — last point (3 points)
SELECT geography::STGeomFromText('MULTIPOINT((1 2), (3 4), (91 0))', 4326);
GO

-- TC-MP-169: Longitude overflow (>15069) — first point
SELECT geography::STGeomFromText('MULTIPOINT((20000 45), (1 2))', 4326);
GO

-- TC-MP-170: Longitude negative overflow (<-15069) — first point
SELECT geography::STGeomFromText('MULTIPOINT((-20000 45), (1 2))', 4326);
GO

-- TC-MP-171: Longitude overflow — second point
SELECT geography::STGeomFromText('MULTIPOINT((1 2), (20000 45))', 4326);
GO

-- TC-MP-172: Longitude overflow — middle point
SELECT geography::STGeomFromText('MULTIPOINT((1 2), (20000 45), (3 4))', 4326);
GO

-- TC-MP-173: STMPointFromText — NULL SRID (should ERROR)
SELECT geometry::STMPointFromText('MULTIPOINT((1 2), (3 4))', NULL);
GO

DECLARE @wkb VARBINARY(MAX) = geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STAsBinary();
SELECT geometry::STMPointFromWKB(@wkb, NULL);
GO

-- TC-MP-175: Geography STMPointFromText — Basic
SELECT geography::STMPointFromText('MULTIPOINT((45 90), (50 100))', 4326);
GO

SELECT CAST(CAST(geography::STMPointFromText('MULTIPOINT((45 90), (50 100))', 4326) AS varbinary(max)) AS geography);
GO

-- TC-MP-176: Geography STMPointFromText — Empty
SELECT geography::STMPointFromText('MULTIPOINT EMPTY', 4326);
GO

-- TC-MP-177: Geography STMPointFromText — Wrong type (should ERROR)
SELECT geography::STMPointFromText('POINT(45 90)', 4326);
GO

-- TC-MP-178: Geography STMPointFromText — NULL input
SELECT geography::STMPointFromText(NULL, 4326);
GO

-- TC-MP-179: Geography STMPointFromText — NULL SRID (should ERROR)
SELECT geography::STMPointFromText('MULTIPOINT((45 90), (50 100))', NULL);
GO

-- TC-MP-180: Geography STMPointFromWKB — Basic
DECLARE @wkb180 VARBINARY(MAX) = geography::STGeomFromText('MULTIPOINT((45 90), (50 100))', 4326).STAsBinary();
SELECT geography::STMPointFromWKB(@wkb180, 4326).STAsText();
GO

-- TC-MP-181: Geography STMPointFromWKB — Wrong type (should ERROR)
DECLARE @wkb181 VARBINARY(MAX) = geography::STGeomFromText('LINESTRING(45 90, 50 100)', 4326).STAsBinary();
SELECT geography::STMPointFromWKB(@wkb181, 4326);
GO

-- TC-MP-182: Geography STMPointFromWKB — NULL input
SELECT geography::STMPointFromWKB(NULL, 4326);
GO

-- TC-MP-183: STNumPoints — 2 points
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STNumPoints();
GO

-- TC-MP-184: STNumPoints — 5 points
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4), (5 6), (7 8), (9 10))', 4326).STNumPoints();
GO

-- TC-MP-185: STNumPoints — Single point
SELECT geometry::STGeomFromText('MULTIPOINT((1 2))', 4326).STNumPoints();
GO

-- TC-MP-186: STNumPoints — Empty
SELECT geometry::STGeomFromText('MULTIPOINT EMPTY', 4326).STNumPoints();
GO

-- TC-MP-187: STGeometryType — 2D
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STGeometryType();
GO

-- TC-MP-188: STGeometryType — Empty
SELECT geometry::STGeomFromText('MULTIPOINT EMPTY', 4326).STGeometryType();
GO

-- TC-MP-189: STGeometryType — Geography
SELECT geography::STGeomFromText('MULTIPOINT((45 90), (50 100))', 4326).STGeometryType();
GO

-- TC-MP-190: STIsEmpty — Not empty
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STIsEmpty();
GO

-- TC-MP-191: STIsEmpty — Empty
SELECT geometry::STGeomFromText('MULTIPOINT EMPTY', 4326).STIsEmpty();
GO

-- TC-MP-192: STIsValid — Valid multipoint
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STIsValid();
GO

-- TC-MP-193: STIsValid — Empty (still valid)
SELECT geometry::STGeomFromText('MULTIPOINT EMPTY', 4326).STIsValid();
GO

-- TC-MP-208: MULTIPOINT Z syntax
SELECT geometry::STGeomFromText('MULTIPOINT Z((1 2 3), (4 5 6))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT Z((1 2 3), (4 5 6))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-209: MULTIPOINT M syntax
SELECT geometry::STGeomFromText('MULTIPOINT M((1 2 3), (4 5 6))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT M((1 2 3), (4 5 6))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-210: MULTIPOINT ZM syntax
SELECT geometry::STGeomFromText('MULTIPOINT ZM((1 2 3 4), (5 6 7 8))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT ZM((1 2 3 4), (5 6 7 8))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MP-211: MULTIPOINT Z EMPTY
SELECT geometry::STGeomFromText('MULTIPOINT Z EMPTY', 4326);
GO

-- TC-MP-212: MULTIPOINT M EMPTY
SELECT geometry::STGeomFromText('MULTIPOINT M EMPTY', 4326);
GO

-- TC-MP-213: MULTIPOINT ZM EMPTY
SELECT geometry::STGeomFromText('MULTIPOINT ZM EMPTY', 4326);
GO

-- TC-MP-214: MULTIPOINT Z without inner parens
SELECT geometry::STGeomFromText('MULTIPOINT Z(1 2 3, 4 5 6)', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTIPOINT Z(1 2 3, 4 5 6)', 4326) AS varbinary(max)) AS geometry);
GO

-- Verify STAsText output
SELECT * FROM TextFromGeometrymultipoint;
GO

-- Verify STDimension (should be 0 for points)
SELECT * FROM DimOfGeometrymultipoint;
GO

-- Verify STNumPoints
SELECT * FROM NumPointsOfGeometrymultipoint;
GO

-- Verify STAsBinary
SELECT * FROM BinaryFromGeometrymultipoint;
GO

-- Verify STSrid
SELECT * FROM SridFromGeometrymultipoint;
GO

-- Verify STIsEmpty
SELECT * FROM EmptyGeometrymultipoint;
GO

-- Verify STIsValid
SELECT * FROM ValidGeometrymultipoint;
GO

-- Verify STGeometryType
SELECT * FROM GeomTypeOfGeometrymultipoint;
GO

-- ============================================================================
-- SECTION: Geometry Spatial Operations (MultiPoint vs MultiPoint)
-- ============================================================================

-- Verify STDisjoint
SELECT * FROM DisjointTempGeommultipoint;
GO

-- Verify STDistance
SELECT * FROM DistanceTempGeommultipoint;
GO

-- Verify STIntersects
SELECT * FROM IntersectsTempGeommultipoint;
GO

-- Verify STEquals
SELECT * FROM EqualsTempGeommultipoint;
GO

-- Verify STContains
SELECT * FROM ContainTempGeommultipoint;
GO

-- Verify = operator
SELECT * FROM equals_opgeommultipoint;
GO

-- Verify <> operator
SELECT * FROM notequal_opgeommultipoint;
GO

-- ============================================================================
-- SECTION: Geometry Spatial Operations (MultiPoint vs Point/LineString)
-- ============================================================================

-- Verify STDisjoint cross-type
SELECT * FROM DisjointTempGeommpsr;
GO

-- Verify STDistance cross-type
SELECT * FROM DistanceTempGeommpsr;
GO

-- Verify STIntersects cross-type
SELECT * FROM IntersectsTempGeommpsr;
GO

-- Verify STEquals cross-type
SELECT * FROM EqualsTempGeommpsr;
GO

-- Verify STContains cross-type
SELECT * FROM ContainTempGeommpsr;
GO

-- Verify = operator cross-type
SELECT * FROM equals_opgeommpsr;
GO

-- Verify <> operator cross-type
SELECT * FROM notequal_opgeommpsr;
GO

SELECT * FROM MultipointGeomFromText;
GO

-- Verify geometry stored as VARBINARY
SELECT ID, CAST(geometryData AS geometry).STAsText() AS text FROM geometryAsVarbinarymultipoint ORDER BY ID;
GO

-- Verify VARBINARY back to geometry
SELECT ID, geometryData.STAsText() AS text FROM VarbinaryAsgeometrymultipoint ORDER BY ID;
GO

-- Verify binary round-trip matches
SELECT a.ID, a.geometryData, CAST(b.geometryData AS VARBINARY(2000)) AS roundtrip_bin
FROM geometryAsVarbinarymultipoint a
JOIN VarbinaryAsgeometrymultipoint b ON a.ID = b.ID
ORDER BY a.ID;
GO

-- Verify geometry stored as VARCHAR
SELECT ID, geometryData FROM geometryAsVarcharmultipoint ORDER BY ID;
GO

-- Verify VARCHAR to geometry
SELECT ID, geometryData.STAsText() AS text FROM VarCharAsgeometrymultipoint ORDER BY ID;
GO

-- Verify geometry to VARCHAR back to geometry
SELECT ID, geometryData.STAsText() AS text FROM GeoVarCharAsgeometrymultipoint ORDER BY ID;
GO

-- ============================================================================
-- SECTION: Geography MultiPoint Property Views
-- ============================================================================

-- Verify STAsText output
SELECT * FROM TextFromGeographymultipoint;
GO

-- Verify STDimension
SELECT * FROM DimOfGeographymultipoint;
GO

-- Verify STNumPoints
SELECT * FROM NumPointsOfGeographymultipoint;
GO

-- Verify STAsBinary
SELECT * FROM BinaryFromGeographymultipoint;
GO

-- Verify STSrid
SELECT * FROM SridFromGeographymultipoint;
GO

-- Verify STIsEmpty
SELECT * FROM EmptyGeographymultipoint;
GO

-- Verify STIsValid
SELECT * FROM ValidGeographymultipoint;
GO

-- Verify STGeometryType
SELECT * FROM GeomTypeOfGeographymultipoint;
GO

-- ============================================================================
-- SECTION: Geography Bytea Round-Trip
-- ============================================================================

SELECT ID, geo_multipoint.STAsText() AS text FROM geographyToByteamultipoint ORDER BY ID;
GO

SELECT ID, geo_multipoint.STSrid AS srid FROM geographyToByteamultipoint ORDER BY ID;
GO

SELECT ID, geo_multipoint.STNumPoints() AS numpoints FROM geographyToByteamultipoint ORDER BY ID;
GO

SELECT ID, CAST(geo_multipoint AS VARBINARY(MAX)) AS binary FROM geographyToByteamultipoint ORDER BY ID;
GO

-- Round-trip: geography → VARBINARY → geography → STAsText
SELECT ID, CAST(CAST(geo_multipoint AS VARBINARY(MAX)) AS geography).STAsText() AS roundtrip_text FROM geographyToByteamultipoint ORDER BY ID;
GO

-- ============================================================================
-- SECTION: Prepared Statement Tables — Geometry
-- ============================================================================

SELECT location.STAsText() AS text FROM GEOSPATIAL_MPGEOMRCV_dt;
GO

SELECT location.STSrid AS srid FROM GEOSPATIAL_MPGEOMRCV_dt;
GO

SELECT CAST(location AS VARBINARY(MAX)) AS binary FROM GEOSPATIAL_MPGEOMRCV_dt;
GO

SELECT CAST(CAST(location AS VARBINARY(MAX)) AS geometry).STAsText() AS roundtrip FROM GEOSPATIAL_MPGEOMRCV_dt;
GO

-- ============================================================================
-- SECTION: Prepared Statement Tables — Geography
-- ============================================================================

SELECT location.STAsText() AS text FROM GEOSPATIAL_MPGEOGRCV_dt;
GO

SELECT location.STSrid AS srid FROM GEOSPATIAL_MPGEOGRCV_dt;
GO

SELECT CAST(location AS VARBINARY(MAX)) AS binary FROM GEOSPATIAL_MPGEOGRCV_dt;
GO

SELECT CAST(CAST(location AS VARBINARY(MAX)) AS geography).STAsText() AS roundtrip FROM GEOSPATIAL_MPGEOGRCV_dt;
GO

-- ============================================================================
-- SECTION: Direct Table Queries — Geometry
-- ============================================================================

-- All rows with STAsText
SELECT id, location.STAsText() AS text FROM GEOSPATIALMULTIPOINTGEOM_dt ORDER BY id;
GO

-- All rows binary round-trip
SELECT id, CAST(CAST(location AS VARBINARY(MAX)) AS geometry).STAsText() AS roundtrip FROM GEOSPATIALMULTIPOINTGEOM_dt ORDER BY id;
GO

-- HasZ and HasM properties
SELECT id, location.STAsText() AS text, location.HasZ AS hasz, location.HasM AS hasm FROM GEOSPATIALMULTIPOINTGEOM_dt ORDER BY id;
GO

-- Invalid instance table
SELECT id, location.STAsText() AS text FROM GEOSPATIALMULTIPOINTGEOM_INVALID_dt ORDER BY id;
GO

-- All rows with STAsText
SELECT id, location.STAsText() AS text FROM GEOSPATIALMULTIPOINTGEOG_dt ORDER BY id;
GO

-- All rows binary round-trip
SELECT id, CAST(CAST(location AS VARBINARY(MAX)) AS geography).STAsText() AS roundtrip FROM GEOSPATIALMULTIPOINTGEOG_dt ORDER BY id;
GO

-- HasZ and HasM properties
SELECT id, location.STAsText() AS text, location.HasZ AS hasz, location.HasM AS hasm FROM GEOSPATIALMULTIPOINTGEOG_dt ORDER BY id;
GO

-- ============================================================================
-- SECTION: Geography Spatial Operations (MultiPoint vs MultiPoint)
-- ============================================================================

-- Verify STDisjoint
SELECT * FROM DisjointTempGeogmultipoint;
GO

-- Verify STDistance
SELECT * FROM DistanceTempGeogmultipoint;
GO

-- Verify STIntersects
SELECT * FROM IntersectsTempGeogmultipoint;
GO

-- Verify STEquals
SELECT * FROM EqualsTempGeogmultipoint;
GO

-- Verify = operator
SELECT * FROM equals_opgeogmultipoint;
GO

-- Verify <> operator
SELECT * FROM notequal_opgeogmultipoint;
GO

-- ============================================================================
-- SECTION: Geography Spatial Operations (MultiPoint vs Point)
-- ============================================================================

-- Verify STDisjoint cross-type
SELECT * FROM DisjointTempGeogmpsr;
GO

-- Verify STDistance cross-type
SELECT * FROM DistanceTempGeogmpsr;
GO

-- Verify STIntersects cross-type
SELECT * FROM IntersectsTempGeogmpsr;
GO

-- Verify STEquals cross-type
SELECT * FROM EqualsTempGeogmpsr;
GO

-- Verify = operator cross-type
SELECT * FROM equals_opgeogmpsr;
GO

-- Verify <> operator cross-type
SELECT * FROM notequal_opgeogmpsr;
GO

-- ============================================================================
-- SECTION: STMPointFromText View — Geography
-- ============================================================================

SELECT * FROM MultipointGeogFromText;
GO

-- ============================================================================
-- SECTION: Geography VARBINARY Cast
-- ============================================================================

-- Verify geography stored as VARBINARY
SELECT ID, CAST(geographyData AS geography).STAsText() AS text FROM geographyAsVarbinarymultipoint ORDER BY ID;
GO

-- ============================================================================
-- SECTION: Geography VARCHAR Cast
-- ============================================================================

-- Verify geography stored as VARCHAR
SELECT ID, geographyData FROM geographyAsVarcharmultipoint ORDER BY ID;
GO

-- Verify VARCHAR to geography
SELECT ID, geographyData.STAsText() AS text FROM VarCharAsgeographymultipoint ORDER BY ID;
GO

-- Verify geography to VARCHAR back to geography
SELECT ID, geographyData.STAsText() AS text FROM GeoVarCharAsgeographymultipoint ORDER BY ID;
GO

-- TC-MP-308: STGeomFromText → STAsText (basic chain)
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STAsText();
GO

-- TC-MP-309: STGeomFromText → STNumPoints
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STNumPoints();
GO

-- TC-MP-310: STGeomFromText → STGeometryType
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STGeometryType();
GO

-- TC-MP-311: STGeomFromText → STIsEmpty
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STIsEmpty();
GO

-- TC-MP-312: STGeomFromText → STIsValid
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STIsValid();
GO

-- TC-MP-313: STGeomFromText → STSrid
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STSrid;
GO

-- TC-MP-314: STGeomFromText → STAsBinary
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STAsBinary();
GO

-- TC-MP-315: STGeomFromText → STDimension
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STDimension();
GO

-- TC-MP-316: STGeomFromText → HasZ
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3), (4 5 6))', 4326).HasZ;
GO

-- TC-MP-317: STGeomFromText → HasM
SELECT geometry::STGeomFromText('MULTIPOINT((1 2 3 4), (5 6 7 8))', 4326).HasM;
GO

-- TC-MP-318: STGeomFromText → STNumGeometries
SELECT geometry::STGeomFromText('MULTIPOINT((1 2), (3 4), (5 6))', 4326).STNumGeometries();
GO

-- geometry::STMPointFromText — Valid Cases

-- Basic 2D multipoint
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2), (3 4))', 0);
SELECT @g.STAsText();
GO

-- Single point
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((5 10))', 0);
SELECT @g.STAsText();
GO

-- Without inner parentheses
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT(1 2, 3 4)', 0);
SELECT @g.STAsText();
GO

-- 3D multipoint
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2 3), (4 5 6))', 0);
SELECT @g.STAsText();
GO

-- 4D multipoint
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2 3 4), (5 6 7 8))', 0);
SELECT @g.STAsText();
GO

-- Empty multipoint
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT EMPTY', 0);
SELECT @g.STAsText();
GO

-- Many points
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((0 0), (1 1), (2 2), (3 3), (4 4), (5 5))', 0);
SELECT @g.STAsText();
GO

-- Negative coordinates
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((-1 -2), (-3 -4))', 0);
SELECT @g.STAsText();
GO

-- Decimal coordinates
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1.5 2.5), (3.75 4.25))', 0);
SELECT @g.STAsText();
GO

-- Large coordinates
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1000000 2000000), (3000000 4000000))', 0);
SELECT @g.STAsText();
GO

-- Duplicate points
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2), (1 2), (1 2))', 0);
SELECT @g.STAsText();
GO

-- With SRID
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2), (3 4))', 4326);
SELECT @g.STAsText();
GO

-- NULL WKT input
DECLARE @g geometry = geometry::STMPointFromText(NULL, 0);
SELECT @g.STAsText();
GO

-- Mixed dimensions (2D and 3D)
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2 3), (4 5))', 0);
SELECT @g.STAsText();
GO

-- NULL Z with M
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2 NULL 4), (5 6 NULL 8))', 0);
SELECT @g.STAsText();
GO

-- ============================================
-- geometry::STMPointFromText — Error Cases
-- ============================================

-- NULL SRID
BEGIN TRY
    DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2), (3 4))', NULL);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Wrong type: POINT
BEGIN TRY
    DECLARE @g geometry = geometry::STMPointFromText('POINT(1 2)', 0);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Wrong type: LINESTRING
BEGIN TRY
    DECLARE @g geometry = geometry::STMPointFromText('LINESTRING(0 0, 1 1)', 0);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Wrong type: POLYGON
BEGIN TRY
    DECLARE @g geometry = geometry::STMPointFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))', 0);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Invalid WKT
BEGIN TRY
    DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2), (3))', 0);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Invalid SRID (negative)
BEGIN TRY
    DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2), (3 4))', -1);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Invalid SRID (too large)
BEGIN TRY
    DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2), (3 4))', 1000000);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- ============================================
-- Binary round-trip
-- ============================================

-- 2D round-trip
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2), (3 4))', 0);
DECLARE @b varbinary(max) = CAST(@g AS varbinary(max));
DECLARE @g2 geometry = CAST(@b AS geometry);
SELECT @g2.STAsText();
GO

-- 3D round-trip
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2 3), (4 5 6))', 0);
DECLARE @b varbinary(max) = CAST(@g AS varbinary(max));
DECLARE @g2 geometry = CAST(@b AS geometry);
SELECT @g2.STAsText();
GO

-- Empty round-trip
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT EMPTY', 0);
DECLARE @b varbinary(max) = CAST(@g AS varbinary(max));
DECLARE @g2 geometry = CAST(@b AS geometry);
SELECT @g2.STAsText();
GO

-- ============================================
-- geography::STMPointFromText — Valid Cases
-- ============================================

-- Basic 2D (lat/lon within range)
DECLARE @g geography = geography::STMPointFromText('MULTIPOINT((50 30), (60 40))', 4326);
SELECT @g.STAsText();
GO

-- Single point
DECLARE @g geography = geography::STMPointFromText('MULTIPOINT((50 30))', 4326);
SELECT @g.STAsText();
GO

-- Empty
DECLARE @g geography = geography::STMPointFromText('MULTIPOINT EMPTY', 4326);
SELECT @g.STAsText();
GO

-- Boundary latitude values
DECLARE @g geography = geography::STMPointFromText('MULTIPOINT((0 90), (0 -90))', 4326);
SELECT @g.STAsText();
GO

-- Boundary longitude values
DECLARE @g geography = geography::STMPointFromText('MULTIPOINT((180 0), (-180 0))', 4326);
SELECT @g.STAsText();
GO

-- NULL WKT
DECLARE @g geography = geography::STMPointFromText(NULL, 4326);
SELECT @g.STAsText();
GO

-- Without inner parentheses
DECLARE @g geography = geography::STMPointFromText('MULTIPOINT(50 30, 60 40)', 4326);
SELECT @g.STAsText();
GO

-- ============================================
-- geography::STMPointFromText — Error Cases
-- ============================================

-- NULL SRID
BEGIN TRY
    DECLARE @g geography = geography::STMPointFromText('MULTIPOINT((50 30))', NULL);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Invalid latitude (> 90)
BEGIN TRY
    DECLARE @g geography = geography::STMPointFromText('MULTIPOINT((50 100), (60 40))', 4326);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Invalid latitude (< -90)
BEGIN TRY
    DECLARE @g geography = geography::STMPointFromText('MULTIPOINT((50 -100), (60 40))', 4326);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Invalid SRID
BEGIN TRY
    DECLARE @g geography = geography::STMPointFromText('MULTIPOINT((50 30))', 0);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Wrong type: POINT
BEGIN TRY
    DECLARE @g geography = geography::STMPointFromText('POINT(50 30)', 4326);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Wrong type: LINESTRING
BEGIN TRY
    DECLARE @g geography = geography::STMPointFromText('LINESTRING(50 30, 60 40)', 4326);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Geography binary round-trip
DECLARE @g geography = geography::STMPointFromText('MULTIPOINT((50 30), (60 40))', 4326);
DECLARE @b varbinary(max) = CAST(@g AS varbinary(max));
DECLARE @g2 geography = CAST(@b AS geography);
SELECT @g2.STAsText();
GO

-- ============================================
-- geometry::STMPointFromWKB — Valid Cases
-- ============================================

-- Basic 2D multipoint from WKB
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2), (3 4))', 0);
DECLARE @b varbinary(max) = @g.STAsBinary();
DECLARE @g2 geometry = geometry::STMPointFromWKB(@b, 0);
SELECT @g2.STAsText();
GO

-- Single point from WKB
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((5 10))', 0);
DECLARE @b varbinary(max) = @g.STAsBinary();
DECLARE @g2 geometry = geometry::STMPointFromWKB(@b, 0);
SELECT @g2.STAsText();
GO

-- Empty multipoint from WKB
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT EMPTY', 0);
DECLARE @b varbinary(max) = @g.STAsBinary();
DECLARE @g2 geometry = geometry::STMPointFromWKB(@b, 0);
SELECT @g2.STAsText();
GO

-- Many points from WKB
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((0 0), (1 1), (2 2), (3 3), (4 4))', 0);
DECLARE @b varbinary(max) = @g.STAsBinary();
DECLARE @g2 geometry = geometry::STMPointFromWKB(@b, 0);
SELECT @g2.STAsText();
GO

-- Negative coordinates from WKB
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((-1 -2), (-3 -4))', 0);
DECLARE @b varbinary(max) = @g.STAsBinary();
DECLARE @g2 geometry = geometry::STMPointFromWKB(@b, 0);
SELECT @g2.STAsText();
GO

-- Decimal coordinates from WKB
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1.5 2.5), (3.75 4.25))', 0);
DECLARE @b varbinary(max) = @g.STAsBinary();
DECLARE @g2 geometry = geometry::STMPointFromWKB(@b, 0);
SELECT @g2.STAsText();
GO

-- Large coordinates from WKB
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1000000 2000000), (3000000 4000000))', 0);
DECLARE @b varbinary(max) = @g.STAsBinary();
DECLARE @g2 geometry = geometry::STMPointFromWKB(@b, 0);
SELECT @g2.STAsText();
GO

-- Duplicate points from WKB
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2), (1 2), (1 2))', 0);
DECLARE @b varbinary(max) = @g.STAsBinary();
DECLARE @g2 geometry = geometry::STMPointFromWKB(@b, 0);
SELECT @g2.STAsText();
GO

-- With SRID
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2), (3 4))', 4326);
DECLARE @b varbinary(max) = @g.STAsBinary();
DECLARE @g2 geometry = geometry::STMPointFromWKB(@b, 4326);
SELECT @g2.STAsText();
GO

-- NULL WKB input
DECLARE @g geometry = geometry::STMPointFromWKB(NULL, 0);
SELECT @g.STAsText();
GO

-- Full round-trip: WKT → WKB → geometry → varbinary → geometry
DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2), (3 4))', 0);
DECLARE @b varbinary(max) = @g.STAsBinary();
DECLARE @g2 geometry = geometry::STMPointFromWKB(@b, 0);
DECLARE @b2 varbinary(max) = CAST(@g2 AS varbinary(max));
DECLARE @g3 geometry = CAST(@b2 AS geometry);
SELECT @g3.STAsText();
GO

-- ============================================
-- geometry::STMPointFromWKB — Error Cases
-- ============================================

-- NULL SRID
BEGIN TRY
    DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2), (3 4))', 0);
    DECLARE @b varbinary(max) = @g.STAsBinary();
    DECLARE @g2 geometry = geometry::STMPointFromWKB(@b, NULL);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Wrong type: POINT WKB
BEGIN TRY
    DECLARE @g geometry = geometry::STPointFromText('POINT(1 2)', 0);
    DECLARE @b varbinary(max) = @g.STAsBinary();
    DECLARE @g2 geometry = geometry::STMPointFromWKB(@b, 0);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Wrong type: LINESTRING WKB
BEGIN TRY
    DECLARE @g geometry = geometry::STLineFromText('LINESTRING(0 0, 1 1)', 0);
    DECLARE @b varbinary(max) = @g.STAsBinary();
    DECLARE @g2 geometry = geometry::STMPointFromWKB(@b, 0);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Wrong type: POLYGON WKB
BEGIN TRY
    DECLARE @g geometry = geometry::STPolyFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))', 0);
    DECLARE @b varbinary(max) = @g.STAsBinary();
    DECLARE @g2 geometry = geometry::STMPointFromWKB(@b, 0);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Invalid SRID (negative)
BEGIN TRY
    DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2), (3 4))', 0);
    DECLARE @b varbinary(max) = @g.STAsBinary();
    DECLARE @g2 geometry = geometry::STMPointFromWKB(@b, -1);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Invalid SRID (too large)
BEGIN TRY
    DECLARE @g geometry = geometry::STMPointFromText('MULTIPOINT((1 2), (3 4))', 0);
    DECLARE @b varbinary(max) = @g.STAsBinary();
    DECLARE @g2 geometry = geometry::STMPointFromWKB(@b, 1000000);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- ============================================
-- geography::STMPointFromWKB — Valid Cases
-- ============================================

-- Basic 2D
DECLARE @g geography = geography::STMPointFromText('MULTIPOINT((50 30), (60 40))', 4326);
DECLARE @b varbinary(max) = @g.STAsBinary();
DECLARE @g2 geography = geography::STMPointFromWKB(@b, 4326);
SELECT @g2.STAsText();
GO

-- Single point
DECLARE @g geography = geography::STMPointFromText('MULTIPOINT((50 30))', 4326);
DECLARE @b varbinary(max) = @g.STAsBinary();
DECLARE @g2 geography = geography::STMPointFromWKB(@b, 4326);
SELECT @g2.STAsText();
GO

-- Empty
DECLARE @g geography = geography::STMPointFromText('MULTIPOINT EMPTY', 4326);
DECLARE @b varbinary(max) = @g.STAsBinary();
DECLARE @g2 geography = geography::STMPointFromWKB(@b, 4326);
SELECT @g2.STAsText();
GO

-- NULL WKB
DECLARE @g geography = geography::STMPointFromWKB(NULL, 4326);
SELECT @g.STAsText();
GO

-- Boundary latitude
DECLARE @g geography = geography::STMPointFromText('MULTIPOINT((0 90), (0 -90))', 4326);
DECLARE @b varbinary(max) = @g.STAsBinary();
DECLARE @g2 geography = geography::STMPointFromWKB(@b, 4326);
SELECT @g2.STAsText();
GO

-- Boundary longitude
DECLARE @g geography = geography::STMPointFromText('MULTIPOINT((180 0), (-180 0))', 4326);
DECLARE @b varbinary(max) = @g.STAsBinary();
DECLARE @g2 geography = geography::STMPointFromWKB(@b, 4326);
SELECT @g2.STAsText();
GO

-- Many points
DECLARE @g geography = geography::STMPointFromText('MULTIPOINT((10 20), (30 40), (50 60))', 4326);
DECLARE @b varbinary(max) = @g.STAsBinary();
DECLARE @g2 geography = geography::STMPointFromWKB(@b, 4326);
SELECT @g2.STAsText();
GO

-- Full round-trip geography
DECLARE @g geography = geography::STMPointFromText('MULTIPOINT((50 30), (60 40))', 4326);
DECLARE @b varbinary(max) = @g.STAsBinary();
DECLARE @g2 geography = geography::STMPointFromWKB(@b, 4326);
DECLARE @b2 varbinary(max) = CAST(@g2 AS varbinary(max));
DECLARE @g3 geography = CAST(@b2 AS geography);
SELECT @g3.STAsText();
GO

-- ============================================
-- geography::STMPointFromWKB — Error Cases
-- ============================================

-- NULL SRID
BEGIN TRY
    DECLARE @g geography = geography::STMPointFromText('MULTIPOINT((50 30))', 4326);
    DECLARE @b varbinary(max) = @g.STAsBinary();
    DECLARE @g2 geography = geography::STMPointFromWKB(@b, NULL);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Invalid SRID
BEGIN TRY
    DECLARE @g geography = geography::STMPointFromText('MULTIPOINT((50 30))', 4326);
    DECLARE @b varbinary(max) = @g.STAsBinary();
    DECLARE @g2 geography = geography::STMPointFromWKB(@b, 0);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Wrong type: POINT WKB
BEGIN TRY
    DECLARE @g geography = geography::STPointFromText('POINT(50 30)', 4326);
    DECLARE @b varbinary(max) = @g.STAsBinary();
    DECLARE @g2 geography = geography::STMPointFromWKB(@b, 4326);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Wrong type: LINESTRING WKB
BEGIN TRY
    DECLARE @g geography = geography::STLineFromText('LINESTRING(50 30, 60 40)', 4326);
    DECLARE @b varbinary(max) = @g.STAsBinary();
    DECLARE @g2 geography = geography::STMPointFromWKB(@b, 4326);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- Wrong type: POLYGON WKB
BEGIN TRY
    DECLARE @g geography = geography::STPolyFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))', 4326);
    DECLARE @b varbinary(max) = @g.STAsBinary();
    DECLARE @g2 geography = geography::STMPointFromWKB(@b, 4326);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO