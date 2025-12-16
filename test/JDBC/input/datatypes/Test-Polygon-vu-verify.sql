-- sla 80000

-- Simple triangle
SELECT geometry::STGeomFromText('POLYGON((0 0, 0 5, 5 5, 0 0))', 4326)
GO

-- Rectangle
SELECT geometry::STGeomFromText('POLYGON((0 0, 0 5, 5 5, 5 0, 0 0))', 4326)
GO

-- Polygon with multiple vertices
SELECT geometry::STGeomFromText('POLYGON((0 0, 2 3, 4 5, 6 4, 4 2, 2 1, 0 0))', 4326)
GO

-- Invalid: Not closed (first and last points don't match)
SELECT geometry::STGeomFromText('POLYGON((0 0, 0 5, 5 5, 0 1))', 4326)
GO

-- Invalid: Self-intersecting polygon
SELECT geometry::STGeomFromText('POLYGON((0 0, 5 5, 5 0, 0 5, 0 0))', 4326)
GO

-- Invalid: Less than 4 points (3 points minimum + closing point)
SELECT geometry::STGeomFromText('POLYGON((0 0, 0 5, 0 0))', 4326)
GO

-- Invalid: Duplicate consecutive points
SELECT geometry::STGeomFromText('POLYGON((0 0, 0 5, 0 5, 5 5, 0 0))', 4326)
GO

-- Valid Z values
SELECT geometry::STGeomFromText('POLYGON((0 0 1, 0 5 2, 5 5 3, 0 0 1))', 4326)
GO

-- Mixed Z values (some NULL)
SELECT geometry::STGeomFromText('POLYGON((0 0 1, 0 5 NULL, 5 5 3, 0 0 1))', 4326)
GO

-- All NULL Z values
SELECT geometry::STGeomFromText('POLYGON((0 0 NULL, 0 5 NULL, 5 5 NULL, 0 0 NULL))', 4326)
GO


-- Very small polygon
SELECT geometry::STGeomFromText('POLYGON((0 0, 0 0.000001, 0.000001 0.000001, 0 0))', 4326)
GO

-- Very large coordinates
SELECT geometry::STGeomFromText('POLYGON((999999 999999, 999999 999999.9, 999999.9 999999.9, 999999 999999))', 4326)
GO

-- Negative coordinates
SELECT geometry::STGeomFromText('POLYGON((-10 -10, -10 -5, -5 -5, -10 -10))', 4326)
GO

-- Polygon with hole (interior ring)
SELECT geometry::STGeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0),(2 2, 2 8, 8 8, 8 2, 2 2))', 4326)
GO

-- Multiple holes
SELECT geometry::STGeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0),
    (1 1, 1 2, 2 2, 2 1, 1 1),
    (3 3, 3 4, 4 4, 4 3, 3 3))', 4326)
GO

-- Test STIsValid()
SELECT geometry::STGeomFromText('POLYGON((0 0, 0 5, 5 5, 0 0))', 4326).STIsValid()
GO

-- Test STArea()
SELECT geometry::STGeomFromText('POLYGON((0 0, 0 5, 5 5, 0 0))', 4326).STArea()
GO


-- Simple polygon
SELECT geography::STGeomFromText('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))', 4326)
GO

-- Polygon crossing the equator
SELECT geography::STGeomFromText('POLYGON((0 -1, 0 1, 1 1, 1 -1, 0 -1))', 4326)
GO

-- Polygon crossing the international date line
SELECT geography::STGeomFromText('POLYGON((179 0, 179 1, -179 1, -179 0, 179 0))', 4326)
GO


-- Polygon covering a hemisphere
SELECT geography::STGeomFromText('POLYGON((0 0, 0 90, 180 0, 0 -90, 0 0))', 4326)
GO

-- Large polygon crossing multiple meridians
SELECT geography::STGeomFromText('POLYGON((0 0, 45 0, 45 45, 0 45, 0 0))', 4326)
GO

-- Polygon near the poles
SELECT geography::STGeomFromText('POLYGON((0 89, 90 89, 180 89, -90 89, 0 89))', 4326)
GO

-- Invalid latitude (>90)
SELECT geography::STGeomFromText('POLYGON((0 91, 1 91, 1 92, 0 92, 0 91))', 4326)
GO

-- Invalid longitude (>180)
SELECT geography::STGeomFromText('POLYGON((181 0, 181 1, 182 1, 182 0, 181 0))', 4326)
GO

-- Polygon larger than a hemisphere (invalid)
SELECT geography::STGeomFromText('POLYGON((0 0, 120 0, 180 0, -120 0, -60 0, 0 0))', 4326)
GO


-- Country-sized polygon (approximate USA bounds)
SELECT geography::STGeomFromText('POLYGON((-125 24, -125 49, -66 49, -66 24, -125 24))', 4326)
GO

-- City-sized polygon
SELECT geography::STGeomFromText('POLYGON((-74.02 40.70, -74.02 40.75, -73.95 40.75, -73.95 40.70, -74.02 40.70))', 4326)
GO

-- Small island
SELECT geography::STGeomFromText('POLYGON((167.95 -16.55, 167.97 -16.55, 167.97 -16.53, 167.95 -16.53, 167.95 -16.55))', 4326)
GO

-- Area calculations (note: returns square meters)
SELECT geography::STGeomFromText('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))', 4326).STArea()
GO

-- Testing validity
SELECT geography::STGeomFromText('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))', 4326).STIsValid()
GO


-- Polygon with hole
SELECT geography::STGeomFromText('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0), (4 4, 4 6, 6 6, 6 4, 4 4))', 4326)
GO

-- Test CAST ( Geometry/Geography As Varbinary )
SELECT ID, geometryData FROM geometryAsVarbinarypolygon ORDER BY ID;
GO

SELECT ID, GeographyData FROM geographyAsVarbinarypolygon ORDER BY ID;
GO

-- Test CAST ( Geometry/Geography As Varchar )
SELECT ID, geometryData FROM geometryAsVarcharpolygon ORDER BY ID;
GO

SELECT ID, GeographyData FROM geographyAsVarcharpolygon ORDER BY ID;
GO

-- Test CAST ( Char As Varbinary )
SELECT ID, geometryData FROM CharAsVarbinaryGeompolygon ORDER BY ID;
GO

SELECT ID, GeographyData FROM CharAsVarbinaryGeogpolygon ORDER BY ID;
GO


-- Test CAST ( Varbinary As Geometry/Geography )
SELECT ID, geometryData FROM VarbinaryAsgeometrypolygon ORDER BY ID;
GO

SELECT ID, GeographyData FROM VarbinaryAsgeographypolygon ORDER BY ID;
GO

-- Test CAST ( Char As Geometry/Geography )
SELECT ID, geometryData FROM CharAsgeometrypolygon ORDER BY ID;
GO

SELECT ID, GeographyData FROM CharAsgeographypolygon ORDER BY ID;
GO

-- Test CAST ( Varchar As Geometry/Geography )
SELECT ID, geometryData FROM VarCharAsgeometrypolygon ORDER BY ID;
GO

SELECT ID, GeographyData FROM VarcharAsgeographypolygon ORDER BY ID;
GO

-- Test CAST ( GeoVarchar As Geometry/Geography )
SELECT ID, geometryData FROM GeoVarCharAsgeometrypolygon ORDER BY ID;
GO

SELECT ID, GeographyData FROM GeoVarcharAsgeographypolygon ORDER BY ID;
GO


-- Test CAST ( Geometry/Geography As  Bytea )
SELECT ID, CAST(geo_polygon AS VARBINARY(2000) ) AS bytea_polygon FROM geometryToByteapolygon ORDER BY ID;
GO

SELECT ID,  CAST(geo_polygon AS VARBINARY(2000)  ) AS bytea_polygon FROM geographyToByteapolygon ORDER BY ID;
GO

SELECT * FROM GEOSPATIALPOLYGONGEOM_dt;
go

SELECT * FROM GEOSPATIALPOLYGONGEOG_dt;
go

-- STDimension
SELECT * FROM DimOfGeometrypolygon;
GO

SELECT * FROM DimOfgeographypolygon;
GO

-- STArea
SELECT * FROM AreaOfGeometrypolygon;
GO

SELECT * FROM AreaOfgeographypolygon;
GO

-- STAsText
SELECT * FROM TextFromGeometrypolygon;
GO

SELECT * FROM TextFromgeographypolygon;
GO

-- STAsBinary
SELECT * FROM BinaryFromGeometrypolygon;
GO

SELECT * FROM BinaryFromgeographypolygon;
GO

-- STSrid
SELECT * FROM SridFromGeometrypolygon;
GO

SELECT * FROM SridFromgeographypolygon;
GO

-- STIsEmpty
SELECT * FROM EmptyGeometrypolygon;
GO

SELECT * FROM Emptygeographypolygon;
GO

-- STIsValid
SELECT * FROM ValidGeometrypolygon;
GO

SELECT * FROM Validgeographypolygon;
GO

-- STIsClosed
SELECT * FROM ClosedGeometrypolygon;
GO

SELECT * FROM Closedgeographypolygon;
GO

-- Operator = ( Equals)
SELECT * FROM equals_opgeompolygon;
GO

SELECT * FROM equals_opgeogpolygon;
GO

SELECT * FROM equals_opgeompolysr;
GO

SELECT * FROM equals_opgeogpolysr;
GO

-- Operator <> ( Not Equals )
SELECT * FROM notequal_opgeompolygon;
GO

SELECT * FROM notequal_opgeogpolygon;
GO

SELECT * FROM notequal_opgeompolysr;
GO

SELECT * FROM notequal_opgeogpolysr;
GO
