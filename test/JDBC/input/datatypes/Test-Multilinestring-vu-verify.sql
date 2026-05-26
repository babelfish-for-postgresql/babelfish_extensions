-- ============================================================================
-- SECTION 1: MultiLineString 2D (XY) — Text Input
-- ============================================================================
-- TC-MLS-001: MultiLineString 2D — Single LineString
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2))', 4326);
GO

-- TC-MLS-001: Roundtrip
SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MLS-002: MultiLineString 2D — Two LineStrings
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2), (3 3, 4 4, 5 5))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2), (3 3, 4 4, 5 5))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MLS-003: MultiLineString 2D — Three LineStrings
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1), (2 2, 3 3), (4 4, 5 5))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1), (2 2, 3 3), (4 4, 5 5))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MLS-004: MultiLineString 2D — Five LineStrings
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 0), (0 1, 1 1), (0 2, 1 2), (0 3, 1 3), (0 4, 1 4))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((0 0, 1 0), (0 1, 1 1), (0 2, 1 2), (0 3, 1 3), (0 4, 1 4))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MLS-005: MultiLineString 2D — Many vertices
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 0, 3 1, 4 0, 5 1, 6 0, 7 1, 8 0, 9 1, 10 0))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 0, 3 1, 4 0, 5 1, 6 0, 7 1, 8 0, 9 1, 10 0))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MLS-006: MultiLineString 2D — Two-point line
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 5 5))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((0 0, 5 5))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MLS-007: MultiLineString 2D — Negative Coordinates
SELECT geometry::STGeomFromText('MULTILINESTRING((-1 -2, -3 -4))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((-1 -2, -3 -4))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MLS-008: MultiLineString 2D — Mixed Positive/Negative
SELECT geometry::STGeomFromText('MULTILINESTRING((-1 2, 3 -4, 0 0))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((-1 2, 3 -4, 0 0))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MLS-009: MultiLineString 2D — Decimal Coordinates
SELECT geometry::STGeomFromText('MULTILINESTRING((1.5 2.7, 3.14159 4.00001))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((1.5 2.7, 3.14159 4.00001))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MLS-010: MultiLineString 2D — Closed ring shape
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 0, 1 1, 0 1, 0 0))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((0 0, 1 0, 1 1, 0 1, 0 0))', 4326) AS varbinary(max)) AS geometry);
GO

-- ============================================================================
-- SECTION 2: MultiLineString 3D (XYZ) — Text Input
-- ============================================================================
-- TC-MLS-011: MultiLineString 3D — Single
SELECT geometry::STGeomFromText('MULTILINESTRING((1 2 3, 4 5 6))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((1 2 3, 4 5 6))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MLS-012: MultiLineString 3D — Three points
SELECT geometry::STGeomFromText('MULTILINESTRING((1 2 3, 4 5 6, 7 8 9))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((1 2 3, 4 5 6, 7 8 9))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MLS-013: MultiLineString 3D — Two LineStrings
SELECT geometry::STGeomFromText('MULTILINESTRING((1 2 3, 4 5 6), (7 8 9, 10 11 12))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((1 2 3, 4 5 6), (7 8 9, 10 11 12))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MLS-014: MultiLineString 3D — Decimal Z
SELECT geometry::STGeomFromText('MULTILINESTRING((1.1 2.2 3.3, 4.4 5.5 6.6))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((1.1 2.2 3.3, 4.4 5.5 6.6))', 4326) AS varbinary(max)) AS geometry);
GO

-- ============================================================================
-- SECTION 3: MultiLineString 2DM (XYM) — Text Input
-- ============================================================================
-- TC-MLS-015: MultiLineString 2DM — Single
SELECT geometry::STGeomFromText('MULTILINESTRING((1 2 NULL 4, 5 6 NULL 8))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((1 2 NULL 4, 5 6 NULL 8))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MLS-016: MultiLineString 2DM — Three points
SELECT geometry::STGeomFromText('MULTILINESTRING((1 2 NULL 10, 3 4 NULL 20, 5 6 NULL 30))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((1 2 NULL 10, 3 4 NULL 20, 5 6 NULL 30))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MLS-017: MultiLineString 2DM — Two LineStrings
SELECT geometry::STGeomFromText('MULTILINESTRING((1 2 NULL 4, 5 6 NULL 8), (7 8 NULL 12, 9 10 NULL 16))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((1 2 NULL 4, 5 6 NULL 8), (7 8 NULL 12, 9 10 NULL 16))', 4326) AS varbinary(max)) AS geometry);
GO

-- ============================================================================
-- SECTION 4: MultiLineString 4D (XYZM) — Text Input
-- ============================================================================
-- TC-MLS-018: MultiLineString 4D — Single
SELECT geometry::STGeomFromText('MULTILINESTRING((1 2 3 4, 5 6 7 8))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((1 2 3 4, 5 6 7 8))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MLS-019: MultiLineString 4D — Three points
SELECT geometry::STGeomFromText('MULTILINESTRING((1 2 3 4, 5 6 7 8, 9 10 11 12))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((1 2 3 4, 5 6 7 8, 9 10 11 12))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MLS-020: MultiLineString 4D — Two LineStrings
SELECT geometry::STGeomFromText('MULTILINESTRING((1 2 3 4, 5 6 7 8), (9 10 11 12, 13 14 15 16))', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((1 2 3 4, 5 6 7 8), (9 10 11 12, 13 14 15 16))', 4326) AS varbinary(max)) AS geometry);
GO

-- ============================================================================
-- SECTION 5: MultiLineString EMPTY
-- ============================================================================
-- TC-MLS-021: MULTILINESTRING EMPTY
SELECT geometry::STGeomFromText('MULTILINESTRING EMPTY', 4326);
GO

SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING EMPTY', 4326) AS varbinary(max)) AS geometry);
GO

SELECT geometry::STGeomFromText('MULTILINESTRING EMPTY', 4326).STIsEmpty();
GO

-- ============================================================================
-- SECTION 6: MultiLineString — SRID Variations
-- ============================================================================
-- TC-MLS-022: SRID 0
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2))', 0);
GO

-- TC-MLS-023: SRID 1
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2))', 1);
GO

-- TC-MLS-024: SRID 999999 (max valid)
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2))', 999999);
GO

-- TC-MLS-025: SRID Negative — should error
BEGIN TRY
    SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1))', -1);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- TC-MLS-026: SRID Out of range — should error
BEGIN TRY
    SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1))', 1000000000);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- ============================================================================
-- SECTION 7: MultiLineString — STAsText Output
-- ============================================================================
-- TC-MLS-027: STAsText — single
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2))', 4326).STAsText();
GO

-- TC-MLS-028: STAsText — two LineStrings
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2), (3 3, 4 4, 5 5))', 4326).STAsText();
GO

-- TC-MLS-029: STAsText — Z input
SELECT geometry::STGeomFromText('MULTILINESTRING((1 2 3, 4 5 6))', 4326).STAsText();
GO

-- TC-MLS-030: STAsText — ZM input
SELECT geometry::STGeomFromText('MULTILINESTRING((1 2 3 4, 5 6 7 8))', 4326).STAsText();
GO

-- TC-MLS-031: STAsText — Empty
SELECT geometry::STGeomFromText('MULTILINESTRING EMPTY', 4326).STAsText();
GO

-- ============================================================================
-- SECTION 8: MultiLineString — STAsBinary Output
-- ============================================================================
-- TC-MLS-032: STAsBinary — single
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2))', 4326).STAsBinary();
GO

-- TC-MLS-033: STAsBinary — two LineStrings
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2), (3 3, 4 4, 5 5))', 4326).STAsBinary();
GO

-- TC-MLS-034: STAsBinary — Empty
SELECT geometry::STGeomFromText('MULTILINESTRING EMPTY', 4326).STAsBinary();
GO

-- ============================================================================
-- SECTION 9: MultiLineString — CAST to/from VARCHAR
-- ============================================================================
-- TC-MLS-035: Geometry to VARCHAR
SELECT CAST(geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2))', 4326) AS varchar(500));
GO

-- TC-MLS-036: Geometry to VARCHAR — two LineStrings
SELECT CAST(geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1), (2 2, 3 3))', 4326) AS varchar(500));
GO

-- TC-MLS-037: VARCHAR to geometry
SELECT CAST(CAST('MULTILINESTRING((0 0, 1 1, 2 2))' AS varchar(500)) AS geometry);
GO

-- TC-MLS-038: VARCHAR to geometry roundtrip
SELECT CAST(CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2))', 4326) AS varchar(500)) AS geometry) AS varchar(500));
GO

-- ============================================================================
-- SECTION 10: MultiLineString — CAST to/from VARBINARY
-- ============================================================================
-- TC-MLS-039: Geometry to VARBINARY
SELECT CAST(geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2))', 4326) AS varbinary(2000));
GO

-- TC-MLS-040: VARBINARY to geometry
SELECT CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2))', 4326) AS varbinary(2000)) AS geometry);
GO

-- TC-MLS-041: VARBINARY round-trip preserves WKT
SELECT CAST(CAST(CAST(geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2), (3 3, 4 4, 5 5))', 4326) AS varbinary(2000)) AS geometry).STAsText() AS varchar(500));
GO

-- ============================================================================
-- SECTION 11: MultiLineString — Full Round-Trip Chains
-- ============================================================================
-- TC-MLS-042: WKT → geometry → WKB → geometry → WKT
DECLARE @g geometry = geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2))', 4326);
DECLARE @b varbinary(max) = @g.STAsBinary();
DECLARE @g2 geometry = geometry::STGeomFromWKB(@b, 4326);
SELECT @g2.STAsText();
GO

-- TC-MLS-043: WKT → varchar → geometry → varchar
DECLARE @s varchar(500) = CAST(geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2), (3 3, 4 4, 5 5))', 4326) AS varchar(500));
DECLARE @g geometry = CAST(@s AS geometry);
SELECT CAST(@g AS varchar(500));
GO

-- TC-MLS-044: WKT → varbinary → geometry → varbinary
DECLARE @v varbinary(max) = CAST(geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2))', 4326) AS varbinary(max));
DECLARE @g geometry = CAST(@v AS geometry);
SELECT CAST(@g AS varbinary(max));
GO

-- ============================================================================
-- SECTION 12: MultiLineString — Case Insensitivity in WKT
-- ============================================================================
-- TC-MLS-045: lowercase
SELECT geometry::STGeomFromText('multilinestring((0 0, 1 1))', 4326);
GO

-- TC-MLS-046: MixedCase
SELECT geometry::STGeomFromText('MultiLineString((0 0, 1 1))', 4326);
GO

-- TC-MLS-047: UPPERCASE
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1))', 4326);
GO

-- ============================================================================
-- SECTION 13: MultiLineString — WKT Error Cases (Negative Tests)
-- ============================================================================
-- TC-MLS-048: Single-point LineString — invalid
BEGIN TRY
    SELECT geometry::STGeomFromText('MULTILINESTRING((0 0))', 4326);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- TC-MLS-049: Mixed valid/invalid LineString
BEGIN TRY
    SELECT geometry::STGeomFromText('MULTILINESTRING((1 1, 3 5),(-5 3))', 4326);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- TC-MLS-050: Missing parens
BEGIN TRY
    SELECT geometry::STGeomFromText('MULTILINESTRING(0 0, 1 1)', 4326);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- TC-MLS-051: 5-coordinate point — invalid
BEGIN TRY
    SELECT geometry::STGeomFromText('MULTILINESTRING((1 2 3 4 5, 6 7 8 9 10))', 4326);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- ============================================================================
-- SECTION 14: MultiLineString — Properties
-- ============================================================================
-- TC-MLS-052: STGeometryType
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2), (3 3, 4 4, 5 5))', 4326).STGeometryType();
GO

-- TC-MLS-053: STDimension
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1))', 4326).STDimension();
GO

-- TC-MLS-054: STNumPoints — single
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 5 5))', 4326).STNumPoints();
GO

-- TC-MLS-055: STNumPoints — multi
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2),(3 3, 4 4))', 4326).STNumPoints();
GO

-- TC-MLS-056: STSrid
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1))', 4326).STSrid;
GO

-- TC-MLS-057: STIsValid — valid
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2))', 4326).STIsValid();
GO

-- TC-MLS-058: STIsValid — non-overlapping
SELECT geometry::STGeomFromText('MULTILINESTRING((1 1, 3 5), (-5 3, -8 -2))', 4326).STIsValid();
GO

-- TC-MLS-059: STIsValid — touches at endpoint
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1), (1 1, 2 2))', 4326).STIsValid();
GO

-- TC-MLS-060: STIsEmpty — non-empty
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1))', 4326).STIsEmpty();
GO

-- TC-MLS-061: STIsEmpty — EMPTY
SELECT geometry::STGeomFromText('MULTILINESTRING EMPTY', 4326).STIsEmpty();
GO

-- ============================================================================
-- SECTION 15: MultiLineString — Geography Type
-- ============================================================================
-- TC-MLS-062: Geography 2D
SELECT geography::STGeomFromText('MULTILINESTRING((10 10, 20 20))', 4326);
GO

SELECT CAST(CAST(geography::STGeomFromText('MULTILINESTRING((10 10, 20 20))', 4326) AS varbinary(max)) AS geography);
GO

-- TC-MLS-063: Geography 2D — Two LineStrings
SELECT geography::STGeomFromText('MULTILINESTRING((10 10, 20 20), (30 30, 40 40))', 4326);
GO

SELECT CAST(CAST(geography::STGeomFromText('MULTILINESTRING((10 10, 20 20), (30 30, 40 40))', 4326) AS varbinary(max)) AS geography);
GO

-- TC-MLS-064: Geography 3D
SELECT geography::STGeomFromText('MULTILINESTRING((10 10 100, 20 20 200))', 4326);
GO

SELECT CAST(CAST(geography::STGeomFromText('MULTILINESTRING((10 10 100, 20 20 200))', 4326) AS varbinary(max)) AS geography);
GO

-- TC-MLS-065: Geography 4D
SELECT geography::STGeomFromText('MULTILINESTRING((10 10 100 1, 20 20 200 2))', 4326);
GO

SELECT CAST(CAST(geography::STGeomFromText('MULTILINESTRING((10 10 100 1, 20 20 200 2))', 4326) AS varbinary(max)) AS geography);
GO

-- TC-MLS-066: Geography EMPTY
SELECT geography::STGeomFromText('MULTILINESTRING EMPTY', 4326);
GO

SELECT geography::STGeomFromText('MULTILINESTRING EMPTY', 4326).STIsEmpty();
GO

-- TC-MLS-067: Geography STAsText
SELECT geography::STGeomFromText('MULTILINESTRING((10 10, 20 20), (30 30, 40 40))', 4326).STAsText();
GO

-- ============================================================================
-- SECTION 16: Geography MultiLineString — Lat/Lon Validation (Negative Tests)
-- ============================================================================
-- TC-MLS-068: Latitude > 90 — should error
BEGIN TRY
    SELECT geography::STGeomFromText('MULTILINESTRING((0 91, 10 10))', 4326);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- TC-MLS-069: Latitude < -90 — should error
BEGIN TRY
    SELECT geography::STGeomFromText('MULTILINESTRING((0 -91, 10 10))', 4326);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- TC-MLS-070: Longitude > 180 — should error
BEGIN TRY
    SELECT geography::STGeomFromText('MULTILINESTRING((181 0, 10 10))', 4326);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- TC-MLS-071: Longitude < -180 — should error
BEGIN TRY
    SELECT geography::STGeomFromText('MULTILINESTRING((-181 0, 10 10))', 4326);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- TC-MLS-072: Invalid coord in second LineString
BEGIN TRY
    SELECT geography::STGeomFromText('MULTILINESTRING((10 10, 20 20), (30 30, 200 30))', 4326);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- ============================================================================
-- SECTION 17: MultiLineString — STMLineFromText / STMLineFromWKB
-- ============================================================================

-- TC-MLS-073: Geometry STMLineFromText — Basic 2D
SELECT geometry::STMLineFromText('MULTILINESTRING((1 2, 3 4))', 4326);
GO

SELECT CAST(CAST(geometry::STMLineFromText('MULTILINESTRING((1 2, 3 4))', 4326) AS varbinary(max)) AS geometry);
GO

-- TC-MLS-074: Geometry STMLineFromText — Two LineStrings
SELECT geometry::STMLineFromText('MULTILINESTRING((1 2, 3 4), (5 6, 7 8))', 4326);
GO

SELECT geometry::STMLineFromText('MULTILINESTRING((1 2, 3 4), (5 6, 7 8))', 4326).STAsText();
GO

-- TC-MLS-075: Geometry STMLineFromText — 3D (XYZ)
SELECT geometry::STMLineFromText('MULTILINESTRING((1 2 3, 4 5 6))', 4326).STAsText();
GO

-- TC-MLS-076: Geometry STMLineFromText — 4D (XYZM)
SELECT geometry::STMLineFromText('MULTILINESTRING((1 2 3 4, 5 6 7 8))', 4326).STAsText();
GO

-- TC-MLS-077: Geometry STMLineFromText — Empty
SELECT geometry::STMLineFromText('MULTILINESTRING EMPTY', 4326);
GO

SELECT geometry::STMLineFromText('MULTILINESTRING EMPTY', 4326).STAsText();
GO

-- TC-MLS-078: Geometry STMLineFromText — Wrong geometry type LINESTRING (should ERROR)
SELECT geometry::STMLineFromText('LINESTRING(1 2, 3 4)', 4326);
GO

-- TC-MLS-079: Geometry STMLineFromText — Wrong geometry type POINT (should ERROR)
SELECT geometry::STMLineFromText('POINT(1 2)', 4326);
GO

-- TC-MLS-080: Geometry STMLineFromText — Wrong geometry type POLYGON (should ERROR)
SELECT geometry::STMLineFromText('POLYGON((0 0, 1 0, 1 1, 0 0))', 4326);
GO

-- TC-MLS-081: Geometry STMLineFromText — Wrong geometry type MULTIPOINT (should ERROR)
SELECT geometry::STMLineFromText('MULTIPOINT((1 2), (3 4))', 4326);
GO

-- TC-MLS-082: Geometry STMLineFromText — NULL input → NULL
SELECT geometry::STMLineFromText(NULL, 4326);
GO

-- TC-MLS-083: Geometry STMLineFromText — NULL SRID (should ERROR)
SELECT geometry::STMLineFromText('MULTILINESTRING((1 2, 3 4))', NULL);
GO

-- TC-MLS-084: Geometry STMLineFromWKB — Basic 2D round-trip
DECLARE @wkb084 VARBINARY(MAX) = geometry::STGeomFromText('MULTILINESTRING((1 2, 3 4))', 4326).STAsBinary();
SELECT geometry::STMLineFromWKB(@wkb084, 4326).STAsText();
GO

-- TC-MLS-085: Geometry STMLineFromWKB — Two LineStrings round-trip
DECLARE @wkb085 VARBINARY(MAX) = geometry::STGeomFromText('MULTILINESTRING((1 2, 3 4), (5 6, 7 8))', 4326).STAsBinary();
SELECT geometry::STMLineFromWKB(@wkb085, 4326).STAsText();
GO

-- TC-MLS-086: Geometry STMLineFromWKB — Wrong type binary LINESTRING (should ERROR)
DECLARE @wkb086 VARBINARY(MAX) = geometry::STGeomFromText('LINESTRING(1 2, 3 4)', 4326).STAsBinary();
SELECT geometry::STMLineFromWKB(@wkb086, 4326);
GO

-- TC-MLS-087: Geometry STMLineFromWKB — Wrong type binary MULTIPOINT (should ERROR)
DECLARE @wkb087 VARBINARY(MAX) = geometry::STGeomFromText('MULTIPOINT((1 2), (3 4))', 4326).STAsBinary();
SELECT geometry::STMLineFromWKB(@wkb087, 4326);
GO

-- TC-MLS-088: Geometry STMLineFromWKB — NULL input → NULL
SELECT geometry::STMLineFromWKB(NULL, 4326);
GO

-- TC-MLS-089: Geometry STMLineFromWKB — NULL SRID (should ERROR)
DECLARE @wkb089 VARBINARY(MAX) = geometry::STGeomFromText('MULTILINESTRING((1 2, 3 4))', 4326).STAsBinary();
SELECT geometry::STMLineFromWKB(@wkb089, NULL);
GO

-- TC-MLS-090: Geography STMLineFromText — Basic
SELECT geography::STMLineFromText('MULTILINESTRING((10 10, 20 20))', 4326).STAsText();
GO

-- TC-MLS-091: Geography STMLineFromText — Two LineStrings
SELECT geography::STMLineFromText('MULTILINESTRING((10 10, 20 20), (30 30, 40 40))', 4326).STAsText();
GO

-- TC-MLS-092: Geography STMLineFromText — Empty
SELECT geography::STMLineFromText('MULTILINESTRING EMPTY', 4326).STAsText();
GO

-- TC-MLS-093: Geography STMLineFromText — Wrong type POINT (should ERROR)
SELECT geography::STMLineFromText('POINT(45 90)', 4326);
GO

-- TC-MLS-094: Geography STMLineFromText — Wrong type LINESTRING (should ERROR)
SELECT geography::STMLineFromText('LINESTRING(10 10, 20 20)', 4326);
GO

-- TC-MLS-095: Geography STMLineFromText — Latitude > 90 (should ERROR)
BEGIN TRY
    SELECT geography::STMLineFromText('MULTILINESTRING((10 91, 20 20))', 4326);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- TC-MLS-096: Geography STMLineFromText — NULL input → NULL
SELECT geography::STMLineFromText(NULL, 4326);
GO

-- TC-MLS-097: Geography STMLineFromText — NULL SRID (should ERROR)
SELECT geography::STMLineFromText('MULTILINESTRING((10 10, 20 20))', NULL);
GO

-- TC-MLS-098: Geography STMLineFromWKB — Basic round-trip
DECLARE @wkb098 VARBINARY(MAX) = geography::STGeomFromText('MULTILINESTRING((10 10, 20 20))', 4326).STAsBinary();
SELECT geography::STMLineFromWKB(@wkb098, 4326).STAsText();
GO

-- TC-MLS-099: Geography STMLineFromWKB — Wrong type binary POINT (should ERROR)
DECLARE @wkb099 VARBINARY(MAX) = geography::STGeomFromText('POINT(45 50)', 4326).STAsBinary();
SELECT geography::STMLineFromWKB(@wkb099, 4326);
GO

-- TC-MLS-100: Geography STMLineFromWKB — NULL input → NULL
SELECT geography::STMLineFromWKB(NULL, 4326);
GO

-- TC-MLS-101: Geography STMLineFromWKB — NULL SRID (should ERROR)
DECLARE @wkb101 VARBINARY(MAX) = geography::STGeomFromText('MULTILINESTRING((10 10, 20 20))', 4326).STAsBinary();
SELECT geography::STMLineFromWKB(@wkb101, NULL);
GO

-- ============================================================================
-- SECTION: Geometry MultiLineString Property Views
-- ============================================================================
SELECT * FROM TextFromGeometrymultilinestring;
GO

SELECT * FROM DimOfGeometrymultilinestring;
GO

SELECT * FROM NumPointsOfGeometrymultilinestring;
GO

SELECT * FROM BinaryFromGeometrymultilinestring;
GO

SELECT * FROM SridFromGeometrymultilinestring;
GO

SELECT * FROM EmptyGeometrymultilinestring;
GO

SELECT * FROM ValidGeometrymultilinestring;
GO

SELECT * FROM GeomTypeOfGeometrymultilinestring;
GO

-- ============================================================================
-- SECTION: Geometry Spatial Operations (MultiLineString vs MultiLineString)
-- ============================================================================
SELECT * FROM DisjointTempGeommultilinestring;
GO

SELECT * FROM DistanceTempGeommultilinestring;
GO

SELECT * FROM IntersectsTempGeommultilinestring;
GO

SELECT * FROM EqualsTempGeommultilinestring;
GO

SELECT * FROM ContainTempGeommultilinestring;
GO

SELECT * FROM equals_opgeommultilinestring;
GO

SELECT * FROM notequal_opgeommultilinestring;
GO

-- ============================================================================
-- SECTION: Geometry Spatial Operations (MultiLineString vs Point/LineString)
-- ============================================================================
SELECT * FROM DisjointTempGeommlsr;
GO

SELECT * FROM DistanceTempGeommlsr;
GO

SELECT * FROM IntersectsTempGeommlsr;
GO

SELECT * FROM EqualsTempGeommlsr;
GO

SELECT * FROM ContainTempGeommlsr;
GO

SELECT * FROM equals_opgeommlsr;
GO

SELECT * FROM notequal_opgeommlsr;
GO

-- ============================================================================
-- SECTION: Geography MultiLineString Property Views
-- ============================================================================
SELECT * FROM TextFromGeographymultilinestring;
GO

SELECT * FROM DimOfGeographymultilinestring;
GO

SELECT * FROM NumPointsOfGeographymultilinestring;
GO

SELECT * FROM BinaryFromGeographymultilinestring;
GO

SELECT * FROM SridFromGeographymultilinestring;
GO

SELECT * FROM EmptyGeographymultilinestring;
GO

SELECT * FROM ValidGeographymultilinestring;
GO

SELECT * FROM GeomTypeOfGeographymultilinestring;
GO

-- ============================================================================
-- SECTION: Geography Spatial Operations (MultiLineString vs MultiLineString)
-- ============================================================================
SELECT * FROM DisjointTempGeogmultilinestring;
GO

SELECT * FROM DistanceTempGeogmultilinestring;
GO

SELECT * FROM IntersectsTempGeogmultilinestring;
GO

SELECT * FROM EqualsTempGeogmultilinestring;
GO

SELECT * FROM equals_opgeogmultilinestring;
GO

SELECT * FROM notequal_opgeogmultilinestring;
GO

-- ============================================================================
-- SECTION: Geography Spatial Operations (MultiLineString vs Point)
-- ============================================================================
SELECT * FROM DisjointTempGeogmlsr;
GO

SELECT * FROM DistanceTempGeogmlsr;
GO

SELECT * FROM IntersectsTempGeogmlsr;
GO

SELECT * FROM EqualsTempGeogmlsr;
GO

SELECT * FROM equals_opgeogmlsr;
GO

SELECT * FROM notequal_opgeogmlsr;
GO

-- ============================================================================
-- SECTION: Geography Bytea Round-Trip
-- ============================================================================
SELECT ID, geo_multilinestring.STAsText() AS text FROM geographyToByteamultilinestring ORDER BY ID;
GO

SELECT ID, geo_multilinestring.STAsBinary() AS binary FROM geographyToByteamultilinestring ORDER BY ID;
GO

-- ============================================================================
-- SECTION: Prepared Statement Tables — Geometry
-- ============================================================================
SELECT location.STAsText() AS geometry FROM GEOSPATIAL_MLSGEOMRCV_dt;
GO

SELECT location.STAsBinary() AS binary FROM GEOSPATIAL_MLSGEOMRCV_dt;
GO

SELECT location.STSrid AS srid FROM GEOSPATIAL_MLSGEOMRCV_dt;
GO

-- ============================================================================
-- SECTION: Prepared Statement Tables — Geography
-- ============================================================================
SELECT location.STAsText() AS geography FROM GEOSPATIAL_MLSGEOGRCV_dt;
GO

SELECT location.STAsBinary() AS binary FROM GEOSPATIAL_MLSGEOGRCV_dt;
GO

SELECT location.STSrid AS srid FROM GEOSPATIAL_MLSGEOGRCV_dt;
GO

-- ============================================================================
-- SECTION: Direct Table Queries — Geometry
-- ============================================================================
SELECT geometryData.STAsText() FROM VarbinaryAsgeometrymultilinestring ORDER BY ID;
GO

SELECT geometryData.STAsText() FROM VarCharAsgeometrymultilinestring ORDER BY ID;
GO

SELECT geometryData.STAsText() FROM GeoVarCharAsgeometrymultilinestring ORDER BY ID;
GO

SELECT geometryData FROM geometryAsVarbinarymultilinestring ORDER BY ID;
GO

SELECT geometryData FROM geometryAsVarcharmultilinestring ORDER BY ID;
GO

-- ============================================================================
-- SECTION: Direct Table Queries — Geography
-- ============================================================================
SELECT geographyData.STAsText() FROM VarCharAsgeographymultilinestring ORDER BY ID;
GO

SELECT geographyData.STAsText() FROM GeoVarCharAsgeographymultilinestring ORDER BY ID;
GO

SELECT geographyData FROM geographyAsVarbinarymultilinestring ORDER BY ID;
GO

SELECT geographyData FROM geographyAsVarcharmultilinestring ORDER BY ID;
GO
