-- STGeomFromText tests with different SRIDs
SELECT geography::STGeomFromText('POINT(45 90)', 4326);
GO

SELECT geography::STGeomFromText('POINT(45 90 30)', 104001);
GO

SELECT geography::STGeomFromText('POINT(45 90 NULL)', 4300);
GO

SELECT geography::STGeomFromText('POINT(45 90 30 1)', 4326);
GO

SELECT geography::STGeomFromText('POINT(45 90 NULL 1)', 4279);
GO

SELECT geography::STGeomFromText('POINT(45 90 30 NULL)', 4733);
GO

SELECT geography::STGeomFromText('POINT(45 90 NULL NULL)', 7844);
GO

SELECT geography::STGeomFromText('POINT EMPTY', 4220);
GO

SELECT geography::STGeomFromText(NULL, 4120);
GO

SELECT geography::STGeomFromText('POINT(45 90)', NULL);
GO

-- STPointFromText tests
SELECT geography::STPointFromText('POINT(45 90)', 4326);
GO

SELECT geography::STPointFromText('POINT(45 90 30)', 4326);
GO

SELECT geography::STPointFromText('POINT(45 90 NULL)', 4326);
GO

SELECT geography::STPointFromText('POINT(45 90 30 1)', 4326);
GO

SELECT geography::STPointFromText('POINT(45 90 NULL 1)', 4326);
GO

SELECT geography::STPointFromText('POINT(45 90 30 NULL)', 4326);
GO

SELECT geography::STPointFromText('POINT(45 90 NULL NULL)', 4326);
GO

SELECT geography::STPointFromText('POINT EMPTY', 4326);
GO

SELECT geography::STPointFromText(NULL, 4326);
GO

-- Test with Point empty
SELECT geography::STPointFromText('POINT	EMPTY', 4326);
GO

SELECT geography::STPointFromText('POINT 
EMPTY', 4326);
GO

SELECT geography::STPointFromText('Point Empty', 4326);
GO

SELECT geography::STPointFromText('point empty', 4326);
GO

-- Geography::Point constructor tests
SELECT geography::Point(90, 45, 4326);
GO

SELECT geography::Point(90, 45, 4121);
GO

SELECT geography::Point(90, 45, 4122);
GO

SELECT geography::Point(90, 45, 0);
GO

SELECT geography::Point(90, 45, NULL);
GO

SELECT geography::Point(NULL, 45, 4326);
GO

SELECT geography::Point(90, NULL, 4326);
GO

-- Test with zero values
SELECT geometry::STGeomFromText('POINT(0 0)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(0 0 0)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(0 0 0 0)', 4326);
GO

SELECT geography::STGeomFromText('POINT(0 0)', 4326);
GO

SELECT geography::STGeomFromText('POINT(0 0 0)', 4326);
GO

SELECT geography::STGeomFromText('POINT(0 0 0 0)', 4326);
GO

-- Test with negative values
SELECT geometry::STGeomFromText('POINT(-1 -1)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(-1 -1 -1)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(-1 -1 -1 -1)', 4326);
GO

SELECT geography::STGeomFromText('POINT(-1 -1)', 4326);
GO

SELECT geography::STGeomFromText('POINT(-1 -1 -1)', 4326);
GO

SELECT geography::STGeomFromText('POINT(-1 -1 -1 -1)', 4326);
GO

-- Scientific notation
SELECT geometry::STGeomFromText('POINT(1.5e2 2.5e-2)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(1.5e2 2.5e-2 3.5e1)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(1.5e2 2.5e-2 3.5e1 4.5e0)', 4326);
GO

SELECT geography::STGeomFromText('POINT(1.5e2 2.5e-2)', 4326);
GO

SELECT geography::STGeomFromText('POINT(1.5e2 2.5e-2 3.5e1)', 4326);
GO

SELECT geography::STGeomFromText('POINT(1.5e2 2.5e-2 3.5e1 4.5e0)', 4326);
GO

-- Edge cases
SELECT geometry::STGeomFromText('POINT(0.0 0.0)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(-3.0 +2.0 0.0)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(0.0 0.0 0.0 0.0)', 4326);
GO

SELECT geography::STGeomFromText('POINT(0.0 0.0)', 4326);
GO

SELECT geography::STGeomFromText('POINT(-0.0 +0.0 0.0)', 4326);
GO

SELECT geography::STGeomFromText('POINT(0.0 0.0 0.0 0.0)', 4326);
GO

-- Decimal Values
SELECT geometry::STGeomFromText('POINT(.23 .45)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(.23 .45)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(.23 0.45 .67)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(.23 .45 0.67 .89)', 4326)
GO

SELECT geography::STGeomFromText('POINT(.23 0.45)', 4326);
GO

SELECT geography::STGeomFromText('POINT(0.23 .45 .67)', 4326);
GO

-- Test with extra whitespace
SELECT geometry::STGeomFromText('  POINT  (  1  1  )  ', 4326);
GO

SELECT geography::STGeomFromText('  POINT  (  1  1  )  ', 4326);
GO

SELECT geography::STGeomFromText('  POINT  (  1  1  NULL 1  )  ', 4326);
GO

SELECT geography::STGeomFromText('  POINT  (  1  1  1       NULL )  ', 4326);
GO

-- Test case sensitivity
SELECT geometry::STGeomFromText('point(1 1 NULL 1)', 4326);
GO

SELECT geometry::STGeomFromText('Point (1 1 1)', 4326);
GO

SELECT geography::STGeomFromText('point(1 1)', 4326);
GO

SELECT geography::STGeomFromText('Point (1 1 1)', 4326);
GO

-- Test invalid WKT (these should raise errors)
SELECT geometry::STGeomFromText('POINT(1)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(1 2 3 4 5)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(1,2)', 4326);
GO

SELECT geography::STGeomFromText('POINT(1)', 4326);
GO

SELECT geography::STGeomFromText('POINT(1 2 3 4 5)', 4326);
GO

SELECT geography::STGeomFromText('POINT(1,2)', 4326);
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT geometry::STGeomFromText('POINT(1 1)', NULL);
GO

SELECT geography::STGeomFromText('POINT(1 1)', NULL);
GO

SELECT geography::STPointFromText('POINT(45 90)', NULL);
GO

-- Tests for common error handling
SELECT geometry::STPointFromText('LINESTRING(0 0, 1 1, 2 2)', 4326);
GO

SELECT geography::STPointFromText('LINESTRING(0 0, 1 1, 2 2)', 4326);
GO

SELECT geometry::STGeomFromText('LINESTRING(0 0, 1 1, 2 2)', 4326);
GO

SELECT geography::STGeomFromText('LINESTRING(0 0, 1 1, 2 2)', 4326);
GO

-- Input length is less than 22 bytes
SELECT CAST(0xE6100000010C000000000000F03F0000000000040 as geometry)
GO

SELECT CAST(0xE6100000010C000000000000F03F0000000000040 as geography)
GO

-- Test with Invalid flags
SELECT CAST(0xE61000000105000000000000F03F0000000000000040 as geometry)
GO

SELECT CAST(0xE61000000105000000000000F03F0000000000000040 as geography)
GO

SELECT CAST(0xE61000000104000000000000F03F0000000000000040 as geometry)
GO

SELECT CAST(0xE61000000104000000000000F03F0000000000000040 as geography)
GO

-- When SRID is above 999999 for geometry 
SELECT CAST(0x40420F00010D000000000000F03F00000000000000400000000000000840 as geometry)
GO

-- When SRID is invalid for geography
SELECT CAST(0x10270000010D000000000000F03F00000000000000400000000000000840 as geography)
GO

-- Latitude is less than -90 and greater than 90 for geography
SELECT CAST(0xE6100000010D000000000000594000000000000000400000000000000840 as geography)
GO

SELECT CAST(0xE6100000010D00000000000059C000000000000000400000000000000840 as geography)
GO

--  Negative Tests for Nan X and Y coordinates in CASTS
SELECT CAST(CAST(0xE6100000010C0000000000000040000000000000F87F as geometry) As Varchar(MAX))
GO

SELECT CAST(CAST(0xE6100000010D0000000000000040000000000000F87F0000000000000840 as geometry) As Varchar(MAX))
GO

SELECT CAST(CAST(0xE6100000010F0000000000000040000000000000F87F0000000000000840000000000000F03F as geometry) As Varchar(MAX))
GO

--  Negative Tests Empty Geometries in CASTS
SELECT CAST(CAST(0x000000000104000000000000084000000000000069400000000000001040 as geometry) As varchar(MAX))
GO

SELECT CAST(CAST(0x000000000104000000000000000001000000fffffffffffffff02 as geometry) As varchar(MAX))
GO

SELECT CAST(CAST(0x000000000104000000000000000001000000ffffffffffffffc01 as geometry) As varchar(MAX))
GO

SELECT CAST(CAST(0x000000000104000000000000000003000000fffffffffffffff01 as geometry) As varchar(MAX))
GO

SELECT CAST(CAST(0x000000000104000000000000000001000000fffffffffffffff02 as geometry) As varchar(MAX))
GO

SELECT CAST(CAST(0x000000000104000001100000000001000000fffffffffffffff01 as geometry) As varchar(MAX))
GO

SELECT CAST(CAST(0x000000000104000000000000000001000000ffffffffffffff01 as geometry) As varchar(MAX))
GO

--  Negative Tests for Nan coordinates
SELECT geometry::STGeomFromText('Point ( 1 NaN 2 3)', 0);
GO

SELECT geometry::STGeomFromText('Point ( NaN 1 2 3)', 0);
GO

SELECT geometry::STGeomFromText('Point ( 1 2 NaN)', 0);
GO

SELECT geometry::STGeomFromText('Point ( 1 2 NULL NaN)', 0);
GO

SELECT geometry::STGeomFromText('Point ( 1 2 NaN 3)', 0);
GO

SELECT geometry::STGeomFromText('Point ( 1 2 3 NaN)', 0);
GO


-- Test with unsupported geometry instances (these should raise errors)
-- TODO: Update these tests as we implement support for each geometry instance

-- LINESTRING
SELECT geometry::STGeomFromText('LINESTRING(0 0, 1 1, 2 2)', 4326);
GO

SELECT geography::STGeomFromText('LINESTRING(0 0, 1 1, 2 2)', 4326);
GO

-- POLYGON
SELECT geometry::STGeomFromText('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))', 4326);
GO

SELECT geography::STGeomFromText('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))', 4326);
GO

-- CIRCULARSTRING
SELECT geometry::STGeomFromText('CIRCULARSTRING(0 0, 1 1, 2 0)', 4326);
GO

SELECT geography::STGeomFromText('CIRCULARSTRING(0 0, 1 1, 2 0)', 4326);
GO

-- MULTIPOINT
SELECT geometry::STGeomFromText('MULTIPOINT((0 0), (1 1), (2 2))', 4326);
GO

SELECT geography::STGeomFromText('MULTIPOINT((0 0), (1 1), (2 2))', 4326);
GO


-- MULTILINESTRING
SELECT geometry::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2), (3 3, 4 4, 5 5))', 4326);
GO

SELECT geography::STGeomFromText('MULTILINESTRING((0 0, 1 1, 2 2), (3 3, 4 4, 5 5))', 4326);
GO

-- MULTIPOLYGON
SELECT geometry::STGeomFromText('MULTIPOLYGON(((0 0, 0 1, 1 1, 1 0, 0 0)), ((2 2, 2 3, 3 3, 3 2, 2 2)))', 4326);
GO

SELECT geography::STGeomFromText('MULTIPOLYGON(((0 0, 0 1, 1 1, 1 0, 0 0)), ((2 2, 2 3, 3 3, 3 2, 2 2)))', 4326);
GO

-- CURVEPOLYGON
SELECT geometry::STGeomFromText('CURVEPOLYGON(CIRCULARSTRING(0 0, 1 1, 2 0, 1 -1, 0 0))', 4326);
GO

SELECT geography::STGeomFromText('CURVEPOLYGON(CIRCULARSTRING(0 0, 1 1, 2 0, 1 -1, 0 0))', 4326);
GO

-- COMPOUNDCURVE
SELECT geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(0 0, 1 1, 2 0), (2 0, 3 1))', 4326);
GO

SELECT geography::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(0 0, 1 1, 2 0), (2 0, 3 1))', 4326);
GO

-- GEOMETRYCOLLECTION
SELECT geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0), LINESTRING(1 1, 2 2))', 4326);
GO

SELECT geography::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0), LINESTRING(1 1, 2 2))', 4326);
GO

-- Test with invalid types (these should raise errors)

-- MULTISURFACE
SELECT geometry::STGeomFromText('MULTISURFACE(CURVEPOLYGON(CIRCULARSTRING(0 0, 1 1, 2 0, 1 -1, 0 0)))', 4326);
GO

SELECT geography::STGeomFromText('MULTISURFACE(CURVEPOLYGON(CIRCULARSTRING(0 0, 1 1, 2 0, 1 -1, 0 0)))', 4326);
GO

-- MULTICURVE
SELECT geometry::STGeomFromText('MULTICURVE(CIRCULARSTRING(0 0, 1 1, 2 0), LINESTRING(3 3, 4 4))', 4326);
GO

SELECT geography::STGeomFromText('MULTICURVE(CIRCULARSTRING(0 0, 1 1, 2 0), LINESTRING(3 3, 4 4))', 4326);
GO

-- POLYHEDRALSURFACE
SELECT geometry::STGeomFromText('POLYHEDRALSURFACE(((0 0 0, 0 1 0, 1 1 0, 1 0 0, 0 0 0)))', 4326);
GO

SELECT geography::STGeomFromText('POLYHEDRALSURFACE(((0 0 0, 0 1 0, 1 1 0, 1 0 0, 0 0 0)))', 4326);
GO


-- TRIANGLE
SELECT geometry::STGeomFromText('TRIANGLE((0 0, 0 1, 1 0, 0 0))', 4326);
GO

SELECT geography::STGeomFromText('TRIANGLE((0 0, 0 1, 1 0, 0 0))', 4326);
GO

-- TIN
SELECT geometry::STGeomFromText('TIN(((0 0 0, 0 1 0, 1 0 0, 0 0 0)))', 4326);
GO

SELECT geography::STGeomFromText('TIN(((0 0 0, 0 1 0, 1 0 0, 0 0 0)))', 4326);
GO

-- Random input
SELECT geometry::STGeomFromText('BABEL(0 0)', 4326);
GO

SELECT geography::STGeomFromText('BABEL(0 0)', 4326);
GO

-- Test with POINT M in diffrent scenarios (these should raise errors)

SELECT geometry::STGeomFromText('POINT M(1 2 3)', 4326);
GO

SELECT geography::STGeomFromText('POINT M(1 2 3)', 4326);
GO

SELECT geometry::STGeomFromText(CAST('POINT M(1 2 3)' AS CHAR(20)), 4326)
GO

SELECT geography::STGeomFromText(CAST('POINT M(1 2 3)' AS CHAR(20)), 4326)
GO

SELECT geometry::STGeomFromText(CAST('POINT M(1 2 3)' AS VARCHAR(20)), 4326)
GO

SELECT geography::STGeomFromText(CAST('POINT M(1 2 3)' AS VARCHAR(20)), 4326)
GO

SELECT CAST('POINT M ( 1 2 3)' AS geometry)
GO

SELECT CAST('POINT M ( 1 2 3)' AS geography)
GO

SELECT CAST(geometry::STGeomFromText('POINT M(1 2 3 )', 4326) AS bytea)
GO

SELECT CAST(geography::STGeomFromText('POINT M(1 2 3 )', 4326) AS bytea)
GO

SELECT CAST(geometry::STGeomFromText('POINT M(1 2 3)', 4326) AS VARBINARY(100))
GO

SELECT CAST(geography::STGeomFromText('POINT M(1 2 3)', 4326) AS VARBINARY(100))
GO

SELECT CAST(geometry::STGeomFromText(CAST('POINT M(1 2 3)' AS CHAR(20)), 4326) AS VARBINARY(100))
GO

SELECT CAST(geography::STGeomFromText(CAST('POINT M(1 2 3)' AS CHAR(20)), 4326) AS VARBINARY(100))
GO

SELECT CAST(geometry::STGeomFromText(CAST('POINT M(1 2 3)' AS VARCHAR(20)), 4326) AS VARBINARY(100))
GO

SELECT CAST(geography::STGeomFromText(CAST('POINT M(1 2 3)' AS VARCHAR(20)), 4326) AS VARBINARY(100))
GO

SELECT CAST(CAST('POINT M(1 2 3)' AS VARCHAR(100)) AS geometry)
GO

SELECT CAST(CAST('POINT M(1 2 3)' AS VARCHAR(100)) AS geography)
GO

SELECT CAST(CAST(geometry::STGeomFromText('POINT M(1 2 3)', 4326) AS VARBINARY(100)) AS geometry)
GO

SELECT CAST(CAST(geography::STGeomFromText('POINT M(1 2 3)', 4326) AS VARBINARY(100)) AS geography)
GO

SELECT CAST(CAST(geometry::STGeomFromText('POINT M(1 2 3)', 4326) AS VARCHAR(100)) AS geometry)
GO

SELECT CAST(CAST(geography::STGeomFromText('POINT M(1 2 3)', 4326) AS VARCHAR(100)) AS geography)
GO

-- Geography__STFlipCoordinates tests (Not supported by TSQL, it's for internal use)
SELECT sys.STAsText(sys.Geography__STFlipCoordinates(geography::STGeomFromText('POINT(45 90)', 4326)));
GO

SELECT sys.STAsText(sys.Geography__STFlipCoordinates(geography::STGeomFromText('POINT(-180 -90)', 4326)));
GO

SELECT sys.STAsText(sys.Geography__STFlipCoordinates(geography::STGeomFromText('POINT(180 90)', 4326)));
GO

SELECT sys.STAsText(sys.Geography__STFlipCoordinates(geography::STGeomFromText('POINT(1 2 10)', 4326)));    -- 3D point
GO

SELECT sys.STAsText(sys.Geography__STFlipCoordinates(geography::STGeomFromText('POINT(45 90 10 1)', 4326)));    -- 4D point
GO

SELECT sys.STAsText(sys.Geography__STFlipCoordinates(geography::STGeomFromText('POINT EMPTY', 4326)));
GO

-- Test CAST ( Geometry/Geography As Varbinary )
SELECT ID, geometryData FROM geometryAsVarbinary ORDER BY ID;
GO

SELECT ID, GeographyData FROM GeographyAsVarbinary ORDER BY ID;
GO

-- Test CAST ( Geometry/Geography As Varchar )
SELECT ID, geometryData FROM geometryAsVarchar ORDER BY ID;
GO

SELECT ID, GeographyData FROM GeographyAsVarchar ORDER BY ID;
GO

-- Test CAST ( Geometry/Geography As Char )
SELECT ID, geometryData FROM geometryAsChar ORDER BY ID;
GO

SELECT ID, GeographyData FROM GeographyAsChar ORDER BY ID;
GO

-- Test CAST ( Char As Varbinary )
SELECT ID, geometryData FROM CharAsVarbinaryGeom ORDER BY ID;
GO

SELECT ID, GeographyData FROM CharAsVarbinary ORDER BY ID;
GO

-- Test CAST ( Varchar As Varbinary )
SELECT ID, geometryData FROM VarcharAsVarbinaryGeom ORDER BY ID;
GO

SELECT ID, GeographyData FROM VarcharAsVarbinary ORDER BY ID;
GO

-- Test CAST ( Varbinary As Geometry/Geography )
SELECT ID, geometryData FROM VarbinaryAsgeometry ORDER BY ID;
GO

SELECT ID, GeographyData FROM VarbinaryAsGeography ORDER BY ID;
GO

-- Test CAST ( Char As Geometry/Geography )
SELECT ID, geometryData FROM CharAsgeometry ORDER BY ID;
GO

SELECT ID, GeographyData FROM CharAsGeography ORDER BY ID;
GO

-- Test CAST ( Varchar As Geometry/Geography )
SELECT ID, geometryData FROM VarcharAsgeometry ORDER BY ID;
GO

SELECT ID, GeographyData FROM VarcharAsGeography ORDER BY ID;
GO

-- Test CAST ( GeoVarchar As Geometry/Geography )
SELECT ID, geometryData FROM GeoVarcharAsgeometry ORDER BY ID;
GO

SELECT ID, GeographyData FROM GeoVarcharAsGeography ORDER BY ID;
GO

-- Test CAST ( Bytea As Geometry/Geography )
SELECT ID, CAST(bytea_point AS geometry) AS geo_point FROM ByteaTogeometry;
GO

SELECT ID, CAST(bytea_point AS geography) AS geo_point FROM ByteaToGeography;
GO

-- Test CAST ( Geometry/Geography As  Bytea )
SELECT ID, CAST(geo_point AS bytea ) AS bytea_point FROM geometryToBytea;
GO

SELECT ID,  CAST(geo_point AS bytea  ) AS bytea_point FROM GeographyToBytea;
GO

-- STDimension
SELECT * FROM DimOfGeometry;
GO

SELECT * FROM DimOfGeography;
GO

-- STArea
SELECT * FROM AreaOfGeometry;
GO

SELECT * FROM AreaOfGeography;
GO

-- STAsText
SELECT * FROM TextFromGeometry;
GO

SELECT * FROM TextFromGeography;
GO

-- STAsBinary
SELECT * FROM BinaryFromGeometry;
GO

SELECT * FROM BinaryFromGeography;
GO

-- STX, STY, Lat, Long
SELECT * FROM CoordsFromGeometry;
GO

SELECT * FROM CoordsFromGeography;
GO

-- STSrid
SELECT * FROM SridFromGeometry;
GO

SELECT * FROM SridFromGeography;
GO

-- STIsEmpty
SELECT * FROM EmptyGeometry;
GO

SELECT * FROM EmptyGeography;
GO

-- STIsValid
SELECT * FROM ValidGeometry;
GO

SELECT * FROM ValidGeography;
GO

-- STIsClosed
SELECT * FROM ClosedGeometry;
GO

SELECT * FROM ClosedGeography;
GO

-- STDisjoint
SELECT * FROM DisjointTempGeom;
GO

SELECT * FROM DisjointTempGeog;
GO

SELECT * FROM DisjointTempGeomsr;
GO

SELECT * FROM DisjointTempGeogsr;
GO

-- STDistance
SELECT * FROM DistanceTempGeom;
GO

SELECT * FROM DistanceTempGeog;
GO

SELECT * FROM DistanceTempGeomsr;
GO

SELECT * FROM DistanceTempGeogsr;
GO

-- STIntersects
SELECT * FROM IntersectsTempGeom;
GO

SELECT * FROM IntersectsTempGeog;
GO

SELECT * FROM IntersectsTempGeomsr;
GO

SELECT * FROM IntersectsTempGeogsr;
GO


-- STEquals
SELECT * FROM EqualsTempGeom;
GO

SELECT * FROM EqualsTempGeog;
GO

SELECT * FROM EqualsTempGeomsr;
GO

SELECT * FROM EqualsTempGeogsr;
GO

-- STContains
SELECT * FROM ContainTempGeom;
GO

SELECT * FROM ContainsTempGeog;
GO

SELECT * FROM ContainTempGeomsr;
GO

SELECT * FROM ContainsTempGeogsr;
GO

-- Operator = ( Equals)
SELECT * FROM equals_opgeom;
GO

SELECT * FROM equal_opgeog;
GO

SELECT * FROM equals_opgeomsr;
GO

SELECT * FROM equal_opgeogsr;
GO

-- Operator <> ( Not Equals )
SELECT * FROM notequal_opgeom;
GO

SELECT * FROM notequal_opgeog;
GO

SELECT * FROM notequal_opgeomsr;
GO

SELECT * FROM notequal_opgeogsr;
GO
