
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
SELECT ID, CAST(bytea_point AS geometry) AS geo_point FROM ByteaTogeometryline;
GO

SELECT ID, CAST(bytea_point AS geography) AS geo_point FROM ByteaTogeographyline;
GO

-- Test CAST ( Geometry/Geography As  Bytea )
SELECT ID, CAST(geo_point AS VARBINARY(500) ) AS bytea_point FROM geometryToBytealine;
GO

SELECT ID,  CAST(geo_point AS VARBINARY(500)  ) AS bytea_point FROM geographyToBytealine;
GO

SELECT * FROM GEOSPATIALLINEGEOM_dt;
go

SELECT * FROM DimOfGeometryline;
GO

SELECT * FROM AreaOfGeometryline;
GO

SELECT * FROM TextFromGeometryline;
GO

SELECT * FROM BinaryFromGeometryline;
GO

SELECT * FROM SridFromGeometryline;
GO

SELECT * FROM EmptyGeometryline;
GO

SELECT * FROM ValidGeometryline;
GO

SELECT * FROM ClosedGeometryline;
GO

SELECT * FROM DisjointTempGeomline;
GO

SELECT * FROM DistanceTempGeomline;
GO

SELECT * FROM IntersectsTempGeomline;
GO

SELECT * FROM EqualsTempGeomline;
GO

SELECT * FROM ContainTempGeomline;
GO



SELECT * FROM GEOSPATIALLINEGEOG_dt;
go

SELECT * FROM DimOfgeographyline;
GO

SELECT * FROM AreaOfgeographyline;
GO

SELECT * FROM TextFromgeographyline;
GO

SELECT * FROM BinaryFromgeographyline;
GO

SELECT * FROM SridFromgeographyline;
GO

SELECT * FROM Emptygeographyline;
GO

SELECT * FROM Validgeographyline;
GO

SELECT * FROM Closedgeographyline;
GO

SELECT * FROM DisjointTempGeogline;
GO

SELECT * FROM DistanceTempGeogline;
GO

SELECT * FROM IntersectsTempGeogline;
GO

SELECT * FROM EqualsTempGeogline;
GO

SELECT * FROM ContainTempGeogline;
GO


