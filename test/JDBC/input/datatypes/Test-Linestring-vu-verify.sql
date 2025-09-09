

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

Select * from LineGeogFromText
GO

Select * from LineGeomFromText
GO

-- Test CAST ( Geometry/Geography As Varchar )
SELECT ID, geometryData FROM geometryAsVarcharline ORDER BY ID;
GO

SELECT ID, GeographyData FROM geographyAsVarcharline ORDER BY ID;
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