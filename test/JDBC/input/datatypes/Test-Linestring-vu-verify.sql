-- sla 300000

-- STGeomFromText and STLineFromText tests with different SRIDs

SELECT geography::STLineFromText('LINESTRING(1 2, 3 5, 6 4)', 4326);
GO

SELECT geography::STGeomFromText('LINESTRING(3 5 5, 2 4 NULL 2)', 104001);
GO

SELECT geography::STLineFromText('LINESTRING(1 3 NULL 7, 5 7 6 NULL , 4 5 2 NULL)', 4300);
GO

SELECT geography::STGeomFromText('LINESTRING(3 5 5, 2 4 NULL 2)', 4326);
GO

SELECT geometry::STLineFromText('LINESTRING(3 5 5, 2 4 NULL 2, 3 5)', 4279);
GO

SELECT geometry::STGeomFromText('LINESTRING(1 3 NULL 7, 5 7 6 NULL , 4 5 2 NULL)', 4733);
GO

SELECT geometry::STLineFromText('LINESTRING(3 5 5, 2 4 NULL 2, 3 5)', 7844);
GO

SELECT geometry::STGeomFromText('LINESTRING  EMPTY', 4220);
GO

SELECT geometry::STLineFromText(NULL, 4120);
GO


-- Test invalid WKT (these should raise errors)
SELECT geometry::STGeomFromText('LINESTRING(1 2, 1)', 4326);
GO

SELECT geometry::STGeomFromText('LINESTRING(1 2, 2 3 4 4 1)', 4326);
GO

SELECT geography::STGeomFromText('LINESTRING(1 2, 1)', 4326);
GO

SELECT geography::STGeomFromText('LINESTRING(1 2, 2 3 4 4 1)', 4326);
GO

--  Negative Tests for STLineFromText
SELECT geometry::STLineFromText('POINT(1 2 3)', 4326);
GO

SELECT geography::STLineFromText('POINT(1 2 3)', 4326);
GO

--  Negative Tests for Nan coordinates
SELECT geometry::STGeomFromText('LINESTRING(1 2, 1 NaN, 3 4)', 0);
GO

SELECT geometry::STGeomFromText('LINESTRING(1 2, 1 2 NaN, 3 4)', 0);
GO

SELECT geometry::STGeomFromText('LINESTRING(1 2, 1 2, 3 4, NaN 1 2 4)', 0);
GO

SELECT geography::STGeomFromText('LINESTRING(1 2, 1 NaN, 3 4)', 4326);
GO

SELECT geography::STGeomFromText('LINESTRING(1 2, 1 2 NaN, 3 4)', 4326);
GO

SELECT geography::STGeomFromText('LINESTRING(1 2, 1 2, 3 4, NaN 1 2 4)', 4326);
GO

--  Negative Tests for latitudte validation
--  (latitude must be between -90 and 90)
SELECT geography::STGeomFromText('LINESTRING(1 2, 1  100, 3 4)', 4326);
GO

SELECT geography::STGeomFromText('LINESTRING(1 2, 1  3, 3 4, 10 -1000)', 4326);
GO

SELECT CAST('LINESTRING(1 2, 1  3, 3 4, 10 -1000)' AS geography);
GO

SELECT CAST('LINESTRING(1 2, 1  100, 3 4)' AS geography);
GO

SELECT CAST(CAST('LINESTRING(3 5, 2 200)' AS VARCHAR(500)) AS geography)
GO

SELECT CAST(CAST('LINESTRING(1 2, 1  3, 3 4, 10 -1000)' AS VARCHAR(500)) AS geography)
GO

SELECT CAST(0xE61000000105030000000000000000005940000000000000F03F00000000000014400000000000001C400000000000001040000000000000144000000000000000400000000000001840000000000000F8FF01000000010000000001000000FFFFFFFF0000000002 as geography);
GO

-- Input length is less than 80 bytes for x0104 type
SELECT CAST(0xE6100000010403000000000000000000F03F000000000000084000000000000014400000000000001C40000000000000104000000000000001000000010000000001000000FFFFFFFF0000000002 as geometry)
GO

SELECT CAST(0xE6100000010403000000000000000000F03F000000000000084000000000000014400000000000001C40000000000000104000000000000001000000010000000001000000FFFFFFFF0000000002 as geography)
GO

-- Test with Invalid bytes
SELECT CAST(0xE610000001180000000000000840000000000000144000000000000000400000000000001040 as geometry)
GO

SELECT CAST(0xE6100000010903000000000000000000F03F000000000000084000000000000014400000000000001C400000000000001040000000000000144001000000010000000001000000FFFFFFFF0000000002 as geometry)
GO

SELECT CAST(0xE610000001180000000000000840000000000000144000000000000000400000000000001040 as geography)
GO

SELECT CAST(0xE6100000010903000000000000000000F03F000000000000084000000000000014400000000000001C400000000000001040000000000000144001000000010000000001000000FFFFFFFF0000000002 as geography)
GO

-- When SRID is above 999999 for geometry 
SELECT CAST(0x40420F0001140000000000000840000000000000144000000000000000400000000000001040 as geometry)
GO

-- When SRID is invalid for geography
SELECT CAST(0x1027000001140000000000000840000000000000144000000000000000400000000000001040 as geography)
GO

--  Negative Tests for Nan X and Y coordinates in CASTS
SELECT CAST(CAST(0xE61000000114000000000000F87F000000000000004000000000000008400000000000001C40 as geometry) As Varchar(MAX))
GO

SELECT CAST(CAST(0xE6100000010403000000000000000000F03F000000000000F8FF00000000000014400000000000001C400000000000001040000000000000144001000000010000000001000000FFFFFFFF0000000002 as geometry) As Varchar(MAX))
GO

SELECT CAST(CAST(0xE61000000104030000000000000000000000000000000000F03F00000000000000400000000000001440000000000000F8FF000000000000184001000000010000000001000000FFFFFFFF0000000002 as geometry) As Varchar(MAX))
GO

--  Negative Tests Empty Geometries in CASTS
SELECT CAST(CAST(0x000000000104000000000000084000000000000069400000000000001040 as geometry) As varchar(MAX))
GO

SELECT CAST(CAST(0x000000000104000000000000000001000000fffffffffffffff04 as geometry) As varchar(MAX))
GO

SELECT CAST(CAST(0x000000000104000000000000000001000000ffffffffffffffc02 as geometry) As varchar(MAX))
GO

SELECT CAST(CAST(0x000000000104000000000000000003000000fffffffffffffff02 as geometry) As varchar(MAX))
GO

SELECT CAST(CAST(0x000000000104000000000000000002000000fffffffffffffff02 as geometry) As varchar(MAX))
GO

-- Test functions with Invalid geometries
SELECT geography::STGeomFromText('LINESTRING(1 2 , 1 2, 1 2 5 5 )', 4326).STIsValid();
GO

SELECT geometry::STGeomFromText('LINESTRING(1 2 , 1 2, 1 2 5 5 )', 4326).STIsValid();
GO

SELECT geography::STGeomFromText('LINESTRING(1 2 , 1 2, 1 2 5 5 )', 4326).STIsClosed();
GO

SELECT geometry::STGeomFromText('LINESTRING(1 2 , 1 2, 1 2 5 5 )', 4326).STIsClosed();
GO

SELECT geography::STGeomFromText('LINESTRING(1 2 , 1 2, 1 2 5 5 )', 4326).STDimension();
GO

SELECT geometry::STGeomFromText('LINESTRING(1 2 , 1 2, 1 2 5 5 )', 4326).STDimension();
GO

SELECT geography::STGeomFromText('LINESTRING(1 2 , 1 2, 1 2 5 5 )', 4326).STArea();
GO

SELECT geometry::STGeomFromText('LINESTRING(1 2 , 1 2, 1 2 5 5 )', 4326).STArea();
GO

SELECT geography::STGeomFromText('LINESTRING(1 2 , 1 2, 1 2 5 5 )', 4326).STDistance(geography::STGeomFromText('LINESTRING(3 4, 3 4, 3 4 5 5 )', 4326));
GO

SELECT geometry::STGeomFromText('LINESTRING(1 2 , 1 2, 1 2 5 5 )', 4326).STDistance(geometry::STGeomFromText('LINESTRING(3 4, 3 4, 3 4 5 5 )', 4326));
GO

SELECT geography::STGeomFromText('LINESTRING(1 2 , 1 2, 1 2 5 5 )', 4326).STContains(geography::STGeomFromText('LINESTRING(3 4, 3 4, 3 4 5 5 )', 4326));
GO

SELECT geometry::STGeomFromText('LINESTRING(1 2 , 1 2, 1 2 5 5 )', 4326).STContains(geometry::STGeomFromText('LINESTRING(3 4, 3 4, 3 4 5 5 )', 4326));
GO

SELECT geography::STGeomFromText('LINESTRING(1 2 , 1 2, 1 2 5 5 )', 4326).STDisjoint(geography::STGeomFromText('LINESTRING(3 4, 3 4, 3 4 5 5 )', 4326));
GO

SELECT geometry::STGeomFromText('LINESTRING(1 2 , 1 2, 1 2 5 5 )', 4326).STDisjoint(geometry::STGeomFromText('LINESTRING(3 4, 3 4, 3 4 5 5 )', 4326));
GO

SELECT geography::STGeomFromText('LINESTRING(1 2 , 1 2, 1 2 5 5 )', 4326).STIntersects(geography::STGeomFromText('LINESTRING(3 4, 3 4, 3 4 5 5 )', 4326));
GO

SELECT geometry::STGeomFromText('LINESTRING(1 2 , 1 2, 1 2 5 5 )', 4326).STIntersects(geometry::STGeomFromText('LINESTRING(3 4, 3 4, 3 4 5 5 )', 4326));
GO

-- Test for antipodal points
SELECT geography::STLineFromText('LINESTRING(0 0, 180 0)', 4326)
go

SELECT CAST(geography::STLineFromText('LINESTRING(0 0, 180 0)', 4326) AS binary(38));
GO

SELECT CAST(geography::STLineFromText('LINESTRING(0 -90, 0 90)', 4326) AS binary(38));
GO

SELECT CAST(geography::STLineFromText('LINESTRING(0 0, 180 0)', 4326) AS varbinary(38));
GO

SELECT CAST(geography::STLineFromText('LINESTRING(0 -90, 0 90)', 4326) AS varbinary(38));
GO

SELECT CAST(geography::STLineFromText('LINESTRING(0 0, 180 0)', 4326) AS char(38));
GO

-- Test M and Z functions with Linestring
SELECT geometry::STGeomFromText('LINESTRING(0 0 0 1, 1 1 1 2)', 4326).M;
GO

SELECT geometry::STGeomFromText('LINESTRING(0 0 0 1, 1 1 1 2)', 4326).Z;
GO

SELECT geography::STGeomFromText('LINESTRING(0 0 0 1, 1 1 1 2)', 4326).M;
GO

SELECT geography::STGeomFromText('LINESTRING(0 0 0 1, 1 1 1 2)', 4326).Z;
GO

Select * from GEOSPATIALLINEGEOM_INVALID_dt;
GO

Select * from GEOSPATIALLINEGEOG_INVALID_dt;
GO

Select * from LineGeogFromText
GO

Select * from LineGeomFromText
GO

-- Test CAST ( Geometry/Geography As Varbinary )
SELECT ID, geometryData FROM geometryAsVarbinaryline ORDER BY ID;
GO

SELECT ID, GeographyData FROM geographyAsVarbinaryline ORDER BY ID;
GO

-- Test CAST ( Geometry/Geography As Varchar )
SELECT ID, geometryData FROM geometryAsVarcharline ORDER BY ID;
GO

SELECT ID, GeographyData FROM geographyAsVarcharline ORDER BY ID;
GO

-- Test CAST ( Char As Varbinary )
SELECT ID, geometryData FROM CharAsVarbinaryGeomline ORDER BY ID;
GO

SELECT ID, GeographyData FROM CharAsVarbinaryGeogline ORDER BY ID;
GO


-- Test CAST ( Varbinary As Geometry/Geography )
SELECT ID, geometryData FROM VarbinaryAsgeometryline ORDER BY ID;
GO

SELECT ID, GeographyData FROM VarbinaryAsgeographyline ORDER BY ID;
GO

-- Test CAST ( Char As Geometry/Geography )
SELECT ID, geometryData FROM CharAsgeometryline ORDER BY ID;
GO

SELECT ID, GeographyData FROM CharAsgeographyline ORDER BY ID;
GO

-- Test CAST ( Varchar As Geometry/Geography )
SELECT ID, geometryData FROM VarcharAsgeometryline ORDER BY ID;
GO

SELECT ID, GeographyData FROM VarcharAsgeographyline ORDER BY ID;
GO

-- Test CAST ( GeoVarchar As Geometry/Geography )
SELECT ID, geometryData FROM GeoVarcharAsgeometryline ORDER BY ID;
GO

SELECT ID, GeographyData FROM GeoVarcharAsgeographyline ORDER BY ID;
GO

-- Test CAST ( Bytea As Geometry/Geography )
SELECT ID, CAST(bytea_line AS geometry) AS geo_point FROM ByteaTogeometryline;
GO

SELECT ID, CAST(bytea_line AS geography) AS geo_point FROM ByteaTogeographyline;
GO

-- Test CAST ( Geometry/Geography As  Bytea )
SELECT ID, CAST(geo_line AS VARBINARY(500) ) AS bytea_line FROM geometryToBytealine;
GO

SELECT ID,  CAST(geo_line AS VARBINARY(500)  ) AS bytea_line FROM geographyToBytealine;
GO

SELECT * FROM GEOSPATIALLINEGEOM_dt;
go

SELECT * FROM GEOSPATIALLINEGEOG_dt;
go

-- STDimension
SELECT * FROM DimOfGeometryline;
GO

SELECT * FROM DimOfgeographyline;
GO

-- STArea
SELECT * FROM AreaOfGeometryline;
GO

SELECT * FROM AreaOfgeographyline;
GO

-- STAsText
SELECT * FROM TextFromGeometryline;
GO

SELECT * FROM TextFromgeographyline;
GO

-- STAsBinary
SELECT * FROM BinaryFromGeometryline;
GO

SELECT * FROM BinaryFromgeographyline;
GO

-- STSrid
SELECT * FROM SridFromGeometryline;
GO

SELECT * FROM SridFromgeographyline;
GO

-- STIsEmpty
SELECT * FROM EmptyGeometryline;
GO

SELECT * FROM Emptygeographyline;
GO

-- STIsValid
SELECT * FROM ValidGeometryline;
GO

SELECT * FROM Validgeographyline;
GO

-- STIsClosed
SELECT * FROM ClosedGeometryline;
GO

SELECT * FROM Closedgeographyline;
GO

-- STDisjoint
SELECT * FROM DisjointTempGeomline;
GO

SELECT * FROM DisjointTempGeogline;
GO

SELECT * FROM DisjointTempGeoglinesr;
GO

SELECT * FROM DisjointTempGeomlinesr;
GO

-- STDistance
SELECT * FROM DistanceTempGeomline;
GO

SELECT * FROM DistanceTempGeomlinesr;
GO

SELECT * FROM DistanceTempGeogline;
GO

SELECT * FROM DistanceTempGeoglinesr;
GO

-- STIntersects
SELECT * FROM IntersectsTempGeomline;
GO

SELECT * FROM IntersectsTempGeomlinesr;
GO

SELECT * FROM IntersectsTempGeogline;
GO

SELECT * FROM IntersectsTempGeoglinesr;
GO

-- STEquals
SELECT * FROM EqualsTempGeomline;
GO

SELECT * FROM EqualsTempGeomlinesr;
GO

SELECT * FROM EqualsTempGeogline;
GO

SELECT * FROM EqualsTempGeoglinesr;
GO

-- STContains
SELECT * FROM ContainTempGeomline;
GO

SELECT * FROM ContainTempGeomlinesr;
GO

SELECT * FROM ContainTempGeogline;
GO

SELECT * FROM ContainTempGeoglinesr;
GO

-- Operator = ( Equals)
SELECT * FROM equals_opgeomline;
GO

SELECT * FROM equals_opgeogline;
GO

SELECT * FROM equals_opgeomlinesr;
GO

SELECT * FROM equals_opgeoglinesr;
GO

-- Operator <> ( Not Equals )
SELECT * FROM notequal_opgeomline;
GO

SELECT * FROM notequal_opgeogline;
GO

SELECT * FROM notequal_opgeomlinesr;
GO

SELECT * FROM notequal_opgeoglinesr;
GO

-- ============================================================================
-- BABEL-6444: Security regression — crafted varbinary must produce a clean
-- conversion error, never an out-of-bounds read / backend crash.
-- These exercise the bounds checks added in spatialtypes.c (set_dimension_flag
-- npoints guard + get_child_info sentinel guard).
-- ============================================================================

-- Oversized npoints: 2D-complex header claims npoints=1000 but payload is only
-- 22 bytes. Must NOT walk past the buffer in check_nan_coordinates.
SELECT CAST(0x000000000100E8030000000000000000000000000000 as geometry);
GO

SELECT CAST(0x000000000100E8030000000000000000000000000000 as geography);
GO

-- Negative npoints (0xBFFFFFFF): signed*2 overflow used to make check_nan loop
-- ~2.1B times reading OOB. Must be rejected as a clean conversion error.
SELECT CAST(0x000000000100FFFFFFBF000000000000000000000000 as geometry);
GO

-- MultiPoint with empty-child sentinel (figure_offset = 0xFFFFFFFF on a child
-- shape of a non-empty multi): used to dereference figures[0xFFFFFFFF].
SELECT CAST(0xE6100000010401000000000000000000F03F000000000000004001000000010000000003000000FFFFFFFF000000000400000000000000000100000000FFFFFFFF01 as geometry);
GO

-- Truncated 3D point: type 0x0D needs 30 bytes but only 22 are supplied.
SELECT CAST(0x00000000010D000000000000F03F0000000000000040 as geometry);
GO

-- Truncated 2-point LineString: type 0x14 needs 38 bytes but only 22 supplied.
SELECT CAST(0x000000000114000000000000F03F0000000000000040 as geometry);
GO
