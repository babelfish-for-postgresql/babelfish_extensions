--STNumPoints()
SELECT 
    ID,
    geom_type,
    geom.STNumPoints() AS actual_result,
    CASE ID
        WHEN 1 THEN 1     
        WHEN 2 THEN 1     
        WHEN 3 THEN 1     
        WHEN 4 THEN 2      
        WHEN 5 THEN 3      
        WHEN 6 THEN 5      
        WHEN 7 THEN 4      
        WHEN 8 THEN 5      
        WHEN 9 THEN 10    
        WHEN 10 THEN 0    
        WHEN 11 THEN 0     
        WHEN 12 THEN 0    
        WHEN 13 THEN 1     
        WHEN 14 THEN 0     
        WHEN 15 THEN 0    
        WHEN 16 THEN 0     
    END AS expected_result
FROM STNumPoints_geom_test
ORDER BY ID;

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point.STNumPoints();
go

DECLARE @point geometry;
SET @point = geometry::Point(22.34900, -47.65100, 4326);
SELECT @point.STNumPoints ( );
go

SELECT 
    ID,
    geog_type,
    geog.STNumPoints() AS actual_result,
    CASE ID
        WHEN 1 THEN 1
        WHEN 2 THEN 1
        WHEN 3 THEN 2
        WHEN 4 THEN 3
        WHEN 5 THEN 5
        WHEN 6 THEN 4
        WHEN 7 THEN 5
        WHEN 8 THEN 0
        WHEN 9 THEN 0
        WHEN 10 THEN 1     

        WHEN 11 THEN 0     
        WHEN 12 THEN 0     
    END AS expected_result
FROM STNumPoints_geog_test
ORDER BY ID;
go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point.STNumPoints();
go

DECLARE @point geography;
SET @point = geography::Point(47.65100, -122.34900, 4326);
SELECT @point . STNumPoints ( );
go

DECLARE @nullGeom geometry;
SELECT @nullGeom.STNumPoints() AS null_geometry_result;
go


DECLARE @g geometry;  
SET @g = geometry::STGeomFromText('POINT EMPTY', 0);  
SELECT @g.STNumPoints() AS empty_point_geometry;
go

DECLARE @g geography;  
SET @g = geography::STGeomFromText('POINT EMPTY', 4326);  
SELECT @g.STNumPoints() AS empty_point_geography;
go

SELECT CAST(CAST('POINT EMPTY' AS VARCHAR(100)) AS geography).STNumPoints() AS cast_varchar_result;
go

SELECT CAST(CAST('POINT EMPTY' AS CHAR(100)) AS geography).STNumPoints() AS cast_char_result;
go

SELECT * FROM STNumPoints_geom_view ORDER BY ID;
go

SELECT * FROM STNumPoints_geog_view ORDER BY ID;
go

DECLARE @point1 geometry = geometry::STPointFromText('POINT(-122.349 47.651)', 4326);
DECLARE @point2 geometry = geometry::STPointFromText('POINT(-122.349 47.651)', 0);
DECLARE @point3 geometry = geometry::STPointFromText('POINT(-122.349 47.651)', 999999);
SELECT 
    @point1.STNumPoints() AS srid_4326,
    @point2.STNumPoints() AS srid_0,
    @point3.STNumPoints() AS srid_999999;
go

DECLARE @point1 geography = geography::STPointFromText('POINT(-122.349 47.651)', 4326);
DECLARE @point2 geography = geography::STPointFromText('POINT(-122.349 47.651)', 4204);
SELECT 
    @point1.STNumPoints() AS srid_4326,
    @point2.STNumPoints() AS srid_4204;
go
DECLARE @line geometry;
SET @line = geometry::STGeomFromText('LINESTRING(0 0, 1 1, 2 2)', 0);
SELECT @line.STNumPoints();
go

DECLARE @poly geometry;
SET @poly = geometry::STGeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))', 0);
SELECT @poly.STNumPoints();
go

DECLARE @poly geometry;
SET @poly = geometry::STGeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0), (2 2, 8 2, 8 8, 2 8, 2 2))', 0);
SELECT @poly.STNumPoints();
go

DECLARE @pointZ geometry;
SET @pointZ = geometry::STGeomFromText('POINT(0 0 5)', 0);
SELECT @pointZ.STNumPoints();
go

DECLARE @pointZ geography;
SET @pointZ = geography::STGeomFromText('POINT(-122.34 47.65 100)', 4326);
SELECT @pointZ.STNumPoints();
go

DECLARE @pointM geometry;
SET @pointM = geometry::STGeomFromText('POINT(0 0 NULL 5)', 0);
SELECT @pointM.STNumPoints();
go

DECLARE @lineZ geometry;
SET @lineZ = geometry::STGeomFromText('LINESTRING(0 0 0, 1 1 1, 2 2 2)', 0);
SELECT @lineZ.STNumPoints();
go

-- UNION test
SELECT 'geometry' AS source, geom.STNumPoints() AS num_points FROM STNumPoints_geom_test WHERE ID <= 3
UNION ALL
SELECT 'geography' AS source, geog.STNumPoints() AS num_points FROM STNumPoints_geog_test WHERE ID <= 3
ORDER BY source, num_points;
go


SELECT g1.ID, g1.geom_type, g1.geom.STNumPoints() AS geom_points,
       g2.ID, g2.geog_type, g2.geog.STNumPoints() AS geog_points
FROM STNumPoints_geom_test g1
JOIN STNumPoints_geog_test g2 ON g1.geom.STNumPoints() = g2.geog.STNumPoints()
WHERE g1.ID <= 5 AND g2.ID <= 5
ORDER BY g1.ID, g2.ID;
go