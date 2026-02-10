SELECT geometry::STGeomFromText('POINT(1 2)', 4326).STGeometryType();
go

SELECT geometry::STGeomFromText('LINESTRING(0 0, 1 1, 2 2)', 4326).STGeometryType();
go

SELECT geometry::STGeomFromText('POLYGON((0 0, 4 0, 4 4, 0 4, 0 0))', 4326).STGeometryType();
go

SELECT geometry::STPointFromText('POINT EMPTY', 4326).STGeometryType();
go

SELECT geometry::Point(3.0, 4.0, 4326).STGeometryType();
go

SELECT geography::STGeomFromText('POINT(-122.34 47.65)', 4326).STGeometryType();
go

SELECT geography::STGeomFromText('LINESTRING(-122.36 47.65, -122.34 47.66, -122.32 47.65)', 4326).STGeometryType();
go

SELECT geography::STGeomFromText('POLYGON((-122.35 47.64, -122.33 47.64, -122.33 47.66, -122.35 47.66, -122.35 47.64))', 4326).STGeometryType();
go

SELECT geography::STPointFromText('POINT EMPTY', 4326).STGeometryType();
go

SELECT geography::Point(47.65, -122.34, 4326).STGeometryType();
go

SELECT ID, GeomColumn.STGeometryType() AS GeometryType 
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp 
ORDER BY ID;
go

SELECT ID, GeomColumn.STGeometryType() AS GeometryType 
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp 
WHERE GeomColumn.STGeometryType() = 'Point'
ORDER BY ID;
go

SELECT GeomColumn.STGeometryType() AS GeometryType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
GROUP BY GeomColumn.STGeometryType()
ORDER BY GeometryType;
go

SELECT ID, GeogColumn.STGeometryType() AS GeographyType 
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp 
ORDER BY ID;
go

SELECT ID, GeogColumn.STGeometryType() AS GeographyType 
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp 
WHERE GeogColumn.STGeometryType() = 'Point'
ORDER BY ID;
go

SELECT GeogColumn.STGeometryType() AS GeographyType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp
GROUP BY GeogColumn.STGeometryType()
ORDER BY GeographyType;
go

SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOM_View_Temp ORDER BY ID;
go

SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOG_View_Temp ORDER BY ID;
go

DECLARE @geom geometry = geometry::STGeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))', 4326);
SELECT @geom.STGeometryType();
go

DECLARE @geog geography = geography::STGeomFromText('LINESTRING(-122.36 47.65, -122.34 47.66)', 4326);
SELECT @geog.STGeometryType();
go

SELECT 
    GeomColumn.STGeometryType() AS GeomType,
    GeomColumn.STDimension() AS Dimension
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
ORDER BY ID;
go

SELECT 
    GeogColumn.STGeometryType() AS GeogType,
    GeogColumn.STDimension() AS Dimension
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp
ORDER BY ID;
go

SELECT 
    GeomColumn.STGeometryType() AS GeomType,
    GeomColumn.STIsEmpty() AS IsEmpty
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
ORDER BY ID;
go

SELECT 
    GeogColumn.STGeometryType() AS GeogType,
    GeogColumn.STIsEmpty() AS IsEmpty
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp
ORDER BY ID;
go

SELECT geometry::STGeomFromText('POINT(1 2)', 0).STGeometryType();
go

SELECT geography::STGeomFromText('POINT(-122.34 47.65)', 4269).STGeometryType();
go

SELECT ID, GeomColumn.STGeometryType() AS GeometryType 
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp 
ORDER BY ID;
go

SELECT ID, GeomColumn.STGeometryType() AS GeometryType 
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp 
WHERE GeomColumn.STGeometryType() = 'Point'
ORDER BY ID;
go

SELECT GeomColumn.STGeometryType() AS GeometryType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
GROUP BY GeomColumn.STGeometryType()
ORDER BY GeometryType;
go

SELECT ID, GeogColumn.STGeometryType() AS GeographyType 
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp 
ORDER BY ID;
go

SELECT ID, GeogColumn.STGeometryType() AS GeographyType 
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp 
WHERE GeogColumn.STGeometryType() = 'Point'
ORDER BY ID;
go

SELECT GeogColumn.STGeometryType() AS GeographyType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp
GROUP BY GeogColumn.STGeometryType()
ORDER BY GeographyType;
go

SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOM_View_Temp ORDER BY ID;
go

SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOG_View_Temp ORDER BY ID;
go

DECLARE @geom geometry = geometry::STGeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))', 4326);
SELECT @geom.STGeometryType();
go

DECLARE @geog geography = geography::STGeomFromText('LINESTRING(-122.36 47.65, -122.34 47.66)', 4326);
SELECT @geog.STGeometryType();
go

SELECT 
    GeomColumn.STGeometryType() AS GeomType,
    GeomColumn.STDimension() AS Dimension
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
ORDER BY ID;
go

SELECT 
    GeogColumn.STGeometryType() AS GeogType,
    GeogColumn.STDimension() AS Dimension
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp
ORDER BY ID;
go

SELECT 
    GeomColumn.STGeometryType() AS GeomType,
    GeomColumn.STIsEmpty() AS IsEmpty
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
ORDER BY ID;
go

SELECT 
    GeogColumn.STGeometryType() AS GeogType,
    GeogColumn.STIsEmpty() AS IsEmpty
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp
ORDER BY ID;
go

SELECT geometry::STGeomFromText('POINT(1 2)', 0).STGeometryType();
go

SELECT geography::STGeomFromText('POINT(-122.34 47.65)', 4269).STGeometryType();
go

DECLARE @nullGeom geometry = NULL;
SELECT @nullGeom.STGeometryType();
go

DECLARE @nullGeog geography = NULL;
SELECT @nullGeog.STGeometryType();
go

SELECT ID, GeomColumn.STGeometryType() AS GeometryType FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp ORDER BY GeomColumn.STGeometryType();
go

SELECT ID,CASE GeomColumn.STGeometryType() WHEN 'Point' THEN 'Zero Dimensional' WHEN 'LineString' THEN 'One Dimensional' WHEN 'Polygon' THEN 'Two Dimensional'ELSE 'Unknown' END AS DimensionType FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp ORDER BY ID;
go

SELECT * FROM ( SELECT ID, GeomColumn.STGeometryType() AS GeomType FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp ) AS SubQuery WHERE GeomType = 'Point' ORDER BY ID;
go

SELECT g.ID AS GeomID, geo.ID AS GeogID, g.GeomColumn.STGeometryType() AS GeomType, geo.GeogColumn.STGeometryType() AS GeogType FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp g JOIN TestGeospatialMethods3_STGeometryType_GEOG_Temp geo ON g.ID = geo.ID ORDER BY g.ID;
go

SELECT geometry::STGeomFromText('LINESTRING ZM(0 0 0 0, 1 1 1 1, 2 2 2 2)', 4326).STGeometryType();
go

SELECT geography::STGeomFromText('POLYGON((-122.35 47.64 0, -122.33 47.64 0, -122.33 47.66 0, -122.35 47.66 0, -122.35 47.64 0))', 4326).STGeometryType();
go

SELECT geography::STGeomFromText('POINT ZM(-122.34 47.65 100 200)', 4326).STGeometryType();
go

SELECT geometry::STGeomFromText('POINT(0.0000001 0.0000001)', 4326).STGeometryType();
go

SELECT geometry::STGeomFromText('POINT(999999999 999999999)', 0).STGeometryType();
go

SELECT geometry::STGeomFromText('POINT(-100 -200)', 4326).STGeometryType();
go
