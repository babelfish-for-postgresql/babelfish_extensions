

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
SELECT ID, CAST(geo_polygon AS VARBINARY(500) ) AS bytea_polygon FROM geometryToByteapolygon;
GO

SELECT ID,  CAST(geo_polygon AS VARBINARY(500)  ) AS bytea_polygon FROM geographyToByteapolygon;
GO

SELECT * FROM GEOSPATIALPOLYGONGEOM_dt;
go

SELECT * FROM GEOSPATIALPOLYGEOG_dt;
go

Select * from GEOSPATIALPOLYGONGEOM_INVALID_dt;
GO

Select * from GEOSPATIALPOLYGONGEOG_INVALID_dt;
GO

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

-- STDisjoint
SELECT * FROM DisjointTempGeompolygon;
GO

SELECT * FROM DisjointTempGeogpolygon;
GO

SELECT * FROM DisjointTempGeogpolysr;
GO

SELECT * FROM DisjointTempGeompolysr;
GO

-- STDistance
SELECT * FROM DistanceTempGeompolygon;
GO

SELECT * FROM DistanceTempGeompolysr;
GO

SELECT * FROM DistanceTempGeogpolygon;
GO

SELECT * FROM DistanceTempGeogpolysr;
GO

-- STIntersects
SELECT * FROM IntersectsTempGeompolygon;
GO

SELECT * FROM IntersectsTempGeompolysr;
GO

SELECT * FROM IntersectsTempGeogpolygon;
GO

SELECT * FROM IntersectsTempGeogpolysr;
GO

-- STEquals
SELECT * FROM EqualsTempGeompolygon;
GO

SELECT * FROM EqualsTempGeompolysr;
GO

SELECT * FROM EqualsTempGeogpolygon;
GO

SELECT * FROM EqualsTempGeogpolysr;
GO

-- STContains
SELECT * FROM ContainTempGeompolygon;
GO

SELECT * FROM ContainTempGeompolysr;
GO

SELECT * FROM ContainTempGeogpolygon;
GO

SELECT * FROM ContainTempGeogpolysr;
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
