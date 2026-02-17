--STNumPoints()

USE TestSTNumPoints_DB;
GO

-- View tests
SELECT * FROM STNumPoints_geom_view_db ORDER BY ID;
go
SELECT * FROM STNumPoints_geog_view_db ORDER BY ID;
go

-- JOIN test (geom + geog, both DB tables)
SELECT g.ID, g.geom_type, gg.geog_type,
       g.geom.STNumPoints() AS geom_pts, gg.geog.STNumPoints() AS geog_pts
FROM STNumPoints_geom_test_db g
JOIN STNumPoints_geog_test_db gg ON g.ID = gg.ID
ORDER BY g.ID;
go

-- CTE test
WITH PointCTE AS (
    SELECT ID, geom_type, geom.STNumPoints() AS num_points FROM STNumPoints_geom_test_db
)
SELECT * FROM PointCTE WHERE num_points > 0 ORDER BY num_points DESC, geom_type;
go

-- CTE with Window Functions
WITH RankedGeom AS (
    SELECT ID, geom_type, geom.STNumPoints() AS num_points,
           ROW_NUMBER() OVER (ORDER BY geom.STNumPoints() DESC) AS row_num,
           RANK() OVER (ORDER BY geom.STNumPoints() DESC) AS rnk,
           SUM(geom.STNumPoints()) OVER () AS total_pts
    FROM STNumPoints_geom_test_db
)
SELECT * FROM RankedGeom ORDER BY row_num;
go

-- GROUP BY test
SELECT geom_type, COUNT(*) AS cnt, SUM(geom.STNumPoints()) AS total_pts
FROM STNumPoints_geom_test_db
GROUP BY geom_type
ORDER BY total_pts DESC, geom_type;
go

-- ORDER BY test
SELECT ID, geom_type, geom.STNumPoints() AS num_points
FROM STNumPoints_geom_test_db
ORDER BY num_points DESC, ID ASC;
go

-- Nested functions test
SELECT ID, geom_type,
       ABS(geom.STNumPoints() - 5) AS diff_from_5,
       COALESCE(NULLIF(geom.STNumPoints(), 0), -1) AS pts_or_neg1
FROM STNumPoints_geom_test_db
ORDER BY ID;
go

USE MASTER;
go

-- Test STNumPoints() on geometry table with various geometry types
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

-- Test STNumPoints() with STPointFromText
DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point.STNumPoints();
go

DECLARE @point geometry;
SET @point = geometry::Point(22.34900, -47.65100, 4326);
SELECT @point.STNumPoints ( );
go

-- Test STNumPoints() on geography table with various geography types
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

-- Test STNumPoints() on NULL geometry
DECLARE @nullGeom geometry;
SELECT @nullGeom.STNumPoints() AS null_geometry_result;
go

-- Test STNumPoints() on empty point 
DECLARE @g geometry;  
SET @g = geometry::STGeomFromText('POINT EMPTY', 0);  
SELECT @g.STNumPoints() AS empty_point_geometry;
go

DECLARE @g geography;  
SET @g = geography::STGeomFromText('POINT EMPTY', 4326);  
SELECT @g.STNumPoints() AS empty_point_geography;
go

-- Test STNumPoints() with CAST from VARCHAR
SELECT CAST(CAST('POINT EMPTY' AS VARCHAR(100)) AS geography).STNumPoints() AS cast_varchar_result;
go

-- Test STNumPoints() with CAST from CHAR
SELECT CAST(CAST('POINT EMPTY' AS CHAR(100)) AS geography).STNumPoints() AS cast_char_result;
go

-- Test STNumPoints() via geometry view
SELECT * FROM STNumPoints_geom_view ORDER BY ID;
go

-- Test STNumPoints() via geography view
SELECT * FROM STNumPoints_geog_view ORDER BY ID;
go

-- Test STNumPoints() with different SRIDs for geometry
DECLARE @point1 geometry = geometry::STPointFromText('POINT(-122.349 47.651)', 4326);
DECLARE @point2 geometry = geometry::STPointFromText('POINT(-122.349 47.651)', 0);
DECLARE @point3 geometry = geometry::STPointFromText('POINT(-122.349 47.651)', 999999);
SELECT 
    @point1.STNumPoints() AS srid_4326,
    @point2.STNumPoints() AS srid_0,
    @point3.STNumPoints() AS srid_999999;
go

-- Test STNumPoints() with different SRIDs for geography
DECLARE @point1 geography = geography::STPointFromText('POINT(-122.349 47.651)', 4326);
DECLARE @point2 geography = geography::STPointFromText('POINT(-122.349 47.651)', 4204);
SELECT 
    @point1.STNumPoints() AS srid_4326,
    @point2.STNumPoints() AS srid_4204;
go

-- Test STNumPoints() on LineString
DECLARE @line geometry;
SET @line = geometry::STGeomFromText('LINESTRING(0 0, 1 1, 2 2)', 0);
SELECT @line.STNumPoints();
go

-- Test STNumPoints() on simple Polygon
DECLARE @poly geometry;
SET @poly = geometry::STGeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))', 0);
SELECT @poly.STNumPoints();
go

-- Test STNumPoints() on Polygon with hole
DECLARE @poly geometry;
SET @poly = geometry::STGeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0), (2 2, 8 2, 8 8, 2 8, 2 2))', 0);
SELECT @poly.STNumPoints();
go

-- Test STNumPoints() on Point with Z coordinate (geometry)
DECLARE @pointZ geometry;
SET @pointZ = geometry::STGeomFromText('POINT(0 0 5)', 0);
SELECT @pointZ.STNumPoints();
go

-- Test STNumPoints() on Point with Z coordinate (geography)
DECLARE @pointZ geography;
SET @pointZ = geography::STGeomFromText('POINT(-122.34 47.65 100)', 4326);
SELECT @pointZ.STNumPoints();
go

-- Test STNumPoints() on Point with M coordinate
DECLARE @pointM geometry;
SET @pointM = geometry::STGeomFromText('POINT(0 0 NULL 5)', 0);
SELECT @pointM.STNumPoints();
go

-- Test STNumPoints() on LineString with Z coordinates
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

-- Geometry WHERE/ORDER BY/GROUP BY tests
SELECT ID, geom_type FROM STNumPoints_geom_test WHERE geom.STNumPoints() BETWEEN 2 AND 5 ORDER BY ID;
go
SELECT geom.STNumPoints() AS num_points, COUNT(*) AS count FROM STNumPoints_geom_test GROUP BY geom.STNumPoints() HAVING COUNT(*) > 1 ORDER BY num_points;
go

-- Geography WHERE/ORDER BY/GROUP BY tests
SELECT ID, geog_type FROM STNumPoints_geog_test WHERE geog.STNumPoints() BETWEEN 2 AND 5 ORDER BY ID;
go
SELECT geog.STNumPoints() AS num_points, COUNT(*) AS count FROM STNumPoints_geog_test GROUP BY geog.STNumPoints() HAVING COUNT(*) > 1 ORDER BY num_points;
go

-- Geometry CTE test
WITH GeomCTE AS (
    SELECT ID, geom_type, geom.STNumPoints() AS num_points FROM STNumPoints_geom_test
)
SELECT * FROM GeomCTE WHERE num_points > 0 ORDER BY num_points, ID;
go

-- Geometry Window test
SELECT ID, geom_type, geom.STNumPoints() AS num_points,
       ROW_NUMBER() OVER (ORDER BY geom.STNumPoints() DESC) AS row_num
FROM STNumPoints_geom_test ORDER BY row_num;
go

-- Geography CTE test
WITH GeogCTE AS (
    SELECT ID, geog_type, geog.STNumPoints() AS num_points FROM STNumPoints_geog_test
)
SELECT * FROM GeogCTE WHERE num_points > 0 ORDER BY num_points, ID;
go

-- Geography Window test
SELECT ID, geog_type, geog.STNumPoints() AS num_points,
       ROW_NUMBER() OVER (ORDER BY geog.STNumPoints() DESC) AS row_num
FROM STNumPoints_geog_test ORDER BY row_num;
go

-- View tests
SELECT * FROM STNumPoints_geom_view ORDER BY ID;
go
SELECT * FROM STNumPoints_geog_view ORDER BY ID;
go

-- JOIN test (geom + geog, both MASTER tables)
SELECT g.ID, g.geom_type, gg.geog_type,
       g.geom.STNumPoints() AS geom_pts, gg.geog.STNumPoints() AS geog_pts
FROM STNumPoints_geom_test g
JOIN STNumPoints_geog_test gg ON g.ID = gg.ID
ORDER BY g.ID;
go

-- CTE with Window Functions
WITH RankedGeom AS (
    SELECT ID, geom_type, geom.STNumPoints() AS num_points,
           ROW_NUMBER() OVER (ORDER BY geom.STNumPoints() DESC) AS row_num,
           RANK() OVER (ORDER BY geom.STNumPoints() DESC) AS rnk,
           SUM(geom.STNumPoints()) OVER () AS total_pts
    FROM STNumPoints_geom_test
)
SELECT * FROM RankedGeom ORDER BY row_num;
go

-- GROUP BY test
SELECT geom_type, COUNT(*) AS cnt, SUM(geom.STNumPoints()) AS total_pts
FROM STNumPoints_geom_test
GROUP BY geom_type
ORDER BY total_pts DESC, geom_type;
go

-- ORDER BY test
SELECT ID, geom_type, geom.STNumPoints() AS num_points
FROM STNumPoints_geom_test
ORDER BY num_points DESC, ID ASC;
go

-- Nested functions test
SELECT ID, geom_type,
       ABS(geom.STNumPoints() - 5) AS diff_from_5,
       COALESCE(NULLIF(geom.STNumPoints(), 0), -1) AS pts_or_neg1
FROM STNumPoints_geom_test
ORDER BY ID;
go