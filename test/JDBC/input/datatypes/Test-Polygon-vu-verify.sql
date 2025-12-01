-- sla 80000

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
