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
           ROW_NUMBER() OVER (ORDER BY geom.STNumPoints() DESC, ID) AS row_num,
           RANK() OVER (ORDER BY geom.STNumPoints() DESC, ID) AS rnk,
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
       ROW_NUMBER() OVER (ORDER BY geog.STNumPoints() DESC, ID) AS row_num
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
--Parse functions test 

-- geometry::Parse with POINT
DECLARE @geomText NVARCHAR(MAX);
SET @geomText = 'POINT(1.0 2.0)';
SELECT geometry::Parse(@geomText).STAsText() AS ParsedGeometry;
go

-- geometry::Parse with LINESTRING
DECLARE @geomText NVARCHAR(MAX);
SET @geomText = 'LINESTRING(0 0, 1 1, 2 2)';
SELECT geometry::Parse(@geomText).STAsText() AS ParsedGeometry;
go

DECLARE @geomText NVARCHAR(MAX);
SET @geomText = 'POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))';
SELECT geometry::Parse(@geomText).STAsText() AS ParsedGeometry;
go

DECLARE @geogText NVARCHAR(MAX);
SET @geogText = 'POINT(1.0 2.0)';
SELECT geography::Parse(@geogText).STAsText() AS ParsedGeography;
go

DECLARE @geogText NVARCHAR(MAX);
SET @geogText = 'LINESTRING(0 0, 1 1, 2 2)';
SELECT geography::Parse(@geogText).STAsText() AS ParsedGeography;
go

DECLARE @geogText NVARCHAR(MAX);
SET @geogText = 'POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))';
SELECT geography::Parse(@geogText).STAsText() AS ParsedGeography;
go

-- Parse with real-world coordinates 
DECLARE @geomText NVARCHAR(MAX);
SET @geomText = 'POINT(-122.34900 47.65100)';
SELECT geometry::Parse(@geomText).STAsText() AS ParsedGeometry;
go

DECLARE @geogText NVARCHAR(MAX);
SET @geogText = 'POINT(-122.34900 47.65100)';
SELECT geography::Parse(@geogText).STAsText() AS ParsedGeography;
go

-- Parse from table column
SELECT ID, geometry::Parse(GeomColumn.STAsText()).STAsText() AS ParsedGeom FROM TestGeospatialParse_GeomTemp3 ORDER BY ID;
go

SELECT ID, geography::Parse(GeogColumn.STAsText()).STAsText() AS ParsedGeog FROM TestGeospatialParse_GeogTemp3 ORDER BY ID;
go

-- Parse with STEquals in WHERE clause
DECLARE @searchText NVARCHAR(MAX);
SET @searchText = 'POINT(3.0 4.0)';
SELECT ID FROM TestGeospatialParse_GeomTemp3 WHERE geometry::Parse(@searchText).STEquals(GeomColumn) = 1 ORDER BY ID;
go

DECLARE @searchText NVARCHAR(MAX);
SET @searchText = 'POINT(3.0 4.0)';
SELECT ID FROM TestGeospatialParse_GeogTemp3 WHERE geography::Parse(@searchText).STEquals(GeogColumn) = 1 ORDER BY ID;
go

-- Parse with JOIN and STIntersects
DECLARE @refText NVARCHAR(MAX);
SET @refText = 'POINT(3.0 4.0)';
SELECT g1.ID, g2.ID FROM TestGeospatialParse_GeomTemp3 g1 
JOIN TestGeospatialParse_GeomTemp3 g2 ON geometry::Parse(@refText).STIntersects(g1.GeomColumn) = 1 
ORDER BY g1.ID, g2.ID;
go

-- Parse with CASE and STDistance
DECLARE @testText NVARCHAR(MAX);
SET @testText = 'POINT(1.0 2.0)';
SELECT ID, 
CASE WHEN geometry::Parse(@testText).STDistance(GeomColumn) < 5.0 THEN 'Near' ELSE 'Far' END AS Proximity
FROM TestGeospatialParse_GeomTemp3 ORDER BY ID;
go

-- Parse with CTE
DECLARE @refText NVARCHAR(MAX);
SET @refText = 'POINT(3.0 4.0)';
WITH ParseCTE AS (
    SELECT ID, CAST(geometry::Parse(@refText).STDistance(GeomColumn) AS DECIMAL(10,3)) AS Distance  
    FROM TestGeospatialParse_GeomTemp3
)
SELECT * FROM ParseCTE WHERE Distance < 10.0 ORDER BY Distance, ID;
go


-- Parse with cross-database query (geometry)
DECLARE @refText NVARCHAR(MAX);
SET @refText = 'POINT(3.0 4.0)';
SELECT ID, CAST(geometry::Parse(@refText).STDistance(GeomColumn) AS DECIMAL(10,3)) AS Distance 
FROM TestGeospatialParse_DB.dbo.TestGeospatialParse_GeometryTable3 ORDER BY ID;
go

-- Parse with cross-database query (geography)
DECLARE @refText NVARCHAR(MAX);
SET @refText = 'POINT(3.0 4.0)';
SELECT ID, CAST(geography::Parse(@refText).STDistance(GeogColumn) AS DECIMAL(15,2)) AS Distance 
FROM TestGeospatialParse_DB.dbo.TestGeospatialParse_GeographyTable3 ORDER BY ID;
go

-- NULL variable input (geometry)
DECLARE @nullText NVARCHAR(MAX);
SET @nullText = NULL;
SELECT geometry::Parse(@nullText) AS ParsedGeometry;
go

-- NULL variable input (geography)
DECLARE @nullText NVARCHAR(MAX);
SET @nullText = NULL;
SELECT geography::Parse(@nullText) AS ParsedGeography;
go

-- 'NULL' string literal - should error 
DECLARE @nullString NVARCHAR(MAX);
SET @nullString = 'NULL';
SELECT geometry::Parse(@nullString) AS ParsedGeometry;
go

DECLARE @nullString NVARCHAR(MAX);
SET @nullString = 'NULL';
SELECT geography::Parse(@nullString) AS ParsedGeography;
go

-- POINT EMPTY 
DECLARE @emptyPoint NVARCHAR(MAX);
SET @emptyPoint = 'POINT EMPTY';
SELECT geometry::Parse(@emptyPoint).STAsText() AS ParsedGeometry;
go

DECLARE @emptyPoint NVARCHAR(MAX);
SET @emptyPoint = 'POINT EMPTY';
SELECT geography::Parse(@emptyPoint).STAsText() AS ParsedGeography;
go

-- Whitespace handling 
DECLARE @geomText NVARCHAR(MAX);
SET @geomText = ' POINT ( 1.0 2.0 ) ';
SELECT geometry::Parse(@geomText).STAsText() AS ParsedGeometry;
go

DECLARE @geogText NVARCHAR(MAX);
SET @geogText = ' POINT ( 1.0 2.0 ) ';
SELECT geography::Parse(@geogText).STAsText() AS ParsedGeography;
go

-- Parse with different case
DECLARE @lowerText NVARCHAR(MAX);
SET @lowerText = 'point(1.0 2.0)';
SELECT geometry::Parse(@lowerText).STAsText() AS ParsedGeometry;
go

DECLARE @upperText NVARCHAR(MAX);
SET @upperText = 'POINT(1.0 2.0)';
SELECT geography::Parse(@upperText).STAsText() AS ParsedGeography;
go

-- Nested function calls
SELECT ID, geometry::Parse(GeomColumn.STAsText()).STDimension() AS Dimension 
FROM TestGeospatialParse_GeomTemp3 ORDER BY ID;
go

SELECT ID, geography::Parse(GeogColumn.STAsText()).STDimension() AS Dimension 
FROM TestGeospatialParse_GeogTemp3 ORDER BY ID;
go

-- Parse with function results
SELECT geometry::Parse(geometry::Point(1.0, 2.0, 4326).STAsText()).STAsText() AS ParsedFromFunction;
go

SELECT geography::Parse(geography::Point(1.0, 2.0, 4326).STAsText()).STAsText() AS ParsedFromFunction;
go

-- Direct NULL input
SELECT geometry::Parse(NULL);
go

SELECT geography::Parse(NULL);
go

-- 'NULL' string literal
SELECT geometry::Parse('NULL');
go

SELECT geography::Parse('NULL');
go

SELECT geometry::Parse('  NULL   ');
go

-- XYZM coordinates (4D)
SELECT geometry::Parse('POINT(1 2 3 4)').STAsText();
go

SELECT geography::Parse('POINT(1 2 3 4)').STAsText();
go

-- XYZ coordinates (3D)
SELECT geometry::Parse('POINT(1 2 3)').STAsText();
go

SELECT geography::Parse('POINT(1 2 3)').STAsText();
go

-- Invalid: single coordinate - should error
SELECT geometry::Parse('POINT(1)');   
go

SELECT geography::Parse('POINT(1)').STAsText();
go

-- Invalid polygon: insufficient points - should error
SELECT geometry::Parse('POLYGON((0 0, 1 1))');
go

SELECT geography::Parse('POLYGON((0 0, 1 1))');
go

-- Invalid WKT string - should error
SELECT geometry::Parse('hello');
go

SELECT geography::Parse('hello');
go

-- Large coordinate values
SELECT geometry::Parse('POINT(999999999 999999999)').STAsText();
go

SELECT geography::Parse('POINT(999999999 999999999)').STAsText();
go

-- Boundary coordinate values
SELECT geometry::Parse('POINT(-180 -90)').STAsText();
go

SELECT geography::Parse('POINT(-180 -90)').STAsText();
go

-- LINESTRING EMPTY
SELECT geometry::Parse('LINESTRING EMPTY').STAsText();
go

-- Case insensitivity for LINESTRING
SELECT geometry::Parse('lineString(0 0, 1 1)').STAsText();
go

SELECT geography::Parse('LINESTRING EMPTY').STAsText();
go

SELECT geography::Parse('lineString(0 0, 1 1)').STAsText();
go

-- UNION with Parse
SELECT geometry::Parse('POINT(1 2)').STAsText() AS geom
UNION
SELECT geometry::Parse('POINT(3 4)').STAsText()
UNION
SELECT geometry::Parse('NULL').STAsText()
ORDER BY CASE WHEN geom IS NULL THEN 1 ELSE 0 END, geom DESC;
go


-- GROUP BY with spatial type
SELECT GeomColumn.STGeometryType() AS GeomType, 
       COUNT(*) AS Count
FROM TestGeospatialParse_GeomTemp3
GROUP BY GeomColumn.STGeometryType()
ORDER BY GeomType;
go

-- Window function with Parse
SELECT ID, 
       CAST(geometry::Parse('POINT(0 0)').STDistance(GeomColumn) AS DECIMAL(10,3)) AS Distance,
       ROW_NUMBER() OVER (ORDER BY geometry::Parse('POINT(0 0)').STDistance(GeomColumn), ID) AS RowNum
FROM TestGeospatialParse_GeomTemp3;
go

-- CAST result to VARCHAR
SELECT CAST(geometry::Parse('POINT(1 2)').STAsText() AS VARCHAR(100)) AS Result;
go

-- Empty string - should error
SELECT geometry::Parse('');
go

-- hierarchyid::Parse
select hierarchyid::Parse('/1/3/2/');
go

-- hierarchyid::Parse with variable
DECLARE @node hierarchyid;
SET @node = hierarchyid::Parse('/1/3/2/');
SELECT @node AS NodeValue;
go

-- CTE with multiple geometry types
WITH ParseCTE AS (
    SELECT 1 AS ID, geometry::Parse('POINT(1 2)').STAsText() AS GeomText
    UNION ALL
    SELECT 2, geometry::Parse('LINESTRING(0 0, 1 1)').STAsText()
    UNION ALL
    SELECT 3, geometry::Parse('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))').STAsText()
)
SELECT ID, GeomText FROM ParseCTE ORDER BY ID;
go

-- CTE with geography types
WITH GeogCTE AS (
    SELECT 1 AS ID, geography::Parse('POINT(-122.349 47.651)').STAsText() AS GeogText
    UNION ALL
    SELECT 2, geography::Parse('LINESTRING(-122.36 47.65, -122.34 47.66)').STAsText()
)
SELECT ID, GeogText FROM GeogCTE ORDER BY ID;
go

-- Window function with STDimension
SELECT *, ROW_NUMBER() OVER (ORDER BY Dimension) AS RowNum FROM (
    SELECT 1 AS ID, geometry::Parse('POINT(1 2)').STDimension() AS Dimension
    UNION ALL
    SELECT 2, geometry::Parse('LINESTRING(0 0, 1 1)').STDimension()
    UNION ALL
    SELECT 3, geometry::Parse('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))').STDimension()
) AS Results;
go

-- Schema-qualified Parse
SELECT sys.geometry::Parse('POINT(1 2)').STAsText() AS Result;
go

-- Invalid geometry type - should error
SELECT geometry::Parse('INVALID(1 2)');
go

-- GROUP BY with STDimension
SELECT Dimension, COUNT(*) AS Count FROM (
    SELECT geometry::Parse('POINT(1 2)').STDimension() AS Dimension
    UNION ALL
    SELECT geometry::Parse('POINT(3 4)').STDimension()
    UNION ALL
    SELECT geometry::Parse('LINESTRING(0 0, 1 1)').STDimension()
    UNION ALL
    SELECT geometry::Parse('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))').STDimension()
) AS Results
GROUP BY Dimension
ORDER BY Dimension;
go

-- Parse returning geometry object (no STAsText)
SELECT geometry::Parse('POINT(1 2 3 4)');
go

SELECT geometry::Parse('LINESTRING(0 0, 1 1)');
go

SELECT geometry::Parse('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))');
go

SELECT geometry::Parse('POINT(999999999 999999999)');
go

-- Z coordinate (elevation)
SELECT geometry::Parse('POINT Z(1 2 3)');
go

-- M coordinate (measure)
SELECT geometry::Parse('POINT M(1 2 4)');
go

-- M coordinate (measure)
SELECT geometry::Parse('POLYGON M((0 0 0, 0 10 0, 10 10 0, 10 0 0, 0 0 0))');
go

-- geography with XYZM
SELECT geography::Parse('POINT(1 2 3 4)');
go

SELECT geometry::Parse('LINESTRING Z(0 0 0, 1 1 1, 2 2 2)');
go

SELECT geography::Parse('LINESTRING Z(0 0 0, 1 1 1)');
go

SELECT geography::Parse('POINT Z(1 2 3)');
go

SELECT geography::Parse('LINESTRING Z(0 0 0, 1 1 1)');
go

SELECT geography::Parse('POLYGON Z((0 0 0, 0 1 0, 1 1 0, 1 0 0, 0 0 0))');
go

SELECT geography::Parse('point z(1 2 3)');
go

SELECT geography::Parse('POINT ZM(1 2 3 4)');
go

SELECT geography::Parse('LINESTRING ZM(0 0 0 0, 1 1 1 1)');
go

SELECT geography::Parse('point zm(1 2 3 4)');
go

SELECT geography::Parse('POINT(1 2 3 4)');
go

SELECT geography::Parse('LINESTRING(0 0, 1 1)');
go

SELECT geography::Parse('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))');
go

SELECT geography::Parse('POINT M(1 2 4)');
go

SELECT geography::Parse('LINESTRING M(0 0 0, 1 1 1)');
go

SELECT geography::Parse('POLYGON M((0 0 0, 0 1 0, 1 1 0, 1 0 0, 0 0 0))');
go

SELECT geography::Parse('point m(1 2 4)');
go

SELECT geography::Parse('POINT(-122.349 47.651)');
go

--STGeometryType()

USE TestGeospatialMethods3_DB;
go

--  View - Geometry
SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOM_View_db ORDER BY ID;
go

--  View - Geography
SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOG_View_db ORDER BY ID;
go

-- WHERE - Geometry
SELECT ID, GeomColumn.STGeometryType() AS GeomType
FROM TestGeospatialMethods3_STGeometryType_GEOM_db
WHERE GeomColumn.STGeometryType() = 'Point'
ORDER BY ID;
go

--  WHERE - Geography
SELECT ID, GeogColumn.STGeometryType() AS GeogType
FROM TestGeospatialMethods3_STGeometryType_GEOG_db
WHERE GeogColumn.STGeometryType() = 'Point'
ORDER BY ID;
go

--  ORDER BY - Geometry
SELECT ID, GeomColumn.STGeometryType() AS GeomType
FROM TestGeospatialMethods3_STGeometryType_GEOM_db
ORDER BY GeomColumn.STGeometryType() ASC, ID ASC;
go

--  ORDER BY - Geography
SELECT ID, GeogColumn.STGeometryType() AS GeogType
FROM TestGeospatialMethods3_STGeometryType_GEOG_db
ORDER BY GeogColumn.STGeometryType() DESC;
go

--  GROUP BY - Geometry
SELECT GeomColumn.STGeometryType() AS GeomType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOM_db
GROUP BY GeomColumn.STGeometryType()
ORDER BY GeomType;
go

--  GROUP BY - Geography
SELECT GeogColumn.STGeometryType() AS GeogType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOG_db
GROUP BY GeogColumn.STGeometryType()
ORDER BY GeogType;
go

--  HAVING - Geometry
SELECT GeomColumn.STGeometryType() AS GeomType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOM_db
GROUP BY GeomColumn.STGeometryType()
HAVING COUNT(*) > 1
ORDER BY GeomType;
go

--  JOIN on ID
SELECT g.ID, g.GeomColumn.STGeometryType() AS GeomType,
       geo.GeogColumn.STGeometryType() AS GeogType
FROM TestGeospatialMethods3_STGeometryType_GEOM_db g
JOIN TestGeospatialMethods3_STGeometryType_GEOG_db geo ON g.ID = geo.ID
ORDER BY g.ID;
go

--  JOIN on STGeometryType match
SELECT g.ID AS GeomID, geo.ID AS GeogID,
       g.GeomColumn.STGeometryType() AS MatchedType
FROM TestGeospatialMethods3_STGeometryType_GEOM_db g
JOIN TestGeospatialMethods3_STGeometryType_GEOG_db geo
  ON g.GeomColumn.STGeometryType() = geo.GeogColumn.STGeometryType()
ORDER BY g.ID, geo.ID;
go

--  JOIN views
SELECT gv.ID, gv.GeomType, ggv.GeogType
FROM TestGeospatialMethods3_STGeometryType_GEOM_View_db gv
JOIN TestGeospatialMethods3_STGeometryType_GEOG_View_db ggv ON gv.ID = ggv.ID
ORDER BY gv.ID;
go

--  CTE - Geometry
WITH GeomCTE AS (
    SELECT ID, GeomColumn.STGeometryType() AS GeomType
    FROM TestGeospatialMethods3_STGeometryType_GEOM_db
)
SELECT * FROM GeomCTE WHERE GeomType = 'Point' ORDER BY ID;
go

--  CTE - Geography
WITH GeogCTE AS (
    SELECT ID, GeogColumn.STGeometryType() AS GeogType
    FROM TestGeospatialMethods3_STGeometryType_GEOG_db
)
SELECT * FROM GeogCTE WHERE GeogType = 'Polygon' ORDER BY ID;
go

--  CTE Combined
WITH GeomCTE AS (
    SELECT ID, GeomColumn.STGeometryType() AS GeomType
    FROM TestGeospatialMethods3_STGeometryType_GEOM_db
),
GeogCTE AS (
    SELECT ID, GeogColumn.STGeometryType() AS GeogType
    FROM TestGeospatialMethods3_STGeometryType_GEOG_db
)
SELECT g.ID, g.GeomType, gg.GeogType
FROM GeomCTE g
JOIN GeogCTE gg ON g.ID = gg.ID
ORDER BY g.ID;
go

--  Window ROW_NUMBER - Geometry
SELECT ID, GeomColumn.STGeometryType() AS GeomType,
       ROW_NUMBER() OVER (ORDER BY GeomColumn.STGeometryType()) AS RowNum
FROM TestGeospatialMethods3_STGeometryType_GEOM_db
ORDER BY RowNum;
go

--  Window COUNT PARTITION - Geometry
SELECT ID, GeomColumn.STGeometryType() AS GeomType,
       COUNT(*) OVER (PARTITION BY GeomColumn.STGeometryType()) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOM_db
ORDER BY ID;
go

--  Window LAG/LEAD - Geography
SELECT ID, GeogColumn.STGeometryType() AS GeogType,
       LAG(GeogColumn.STGeometryType()) OVER (ORDER BY ID) AS PrevType,
       LEAD(GeogColumn.STGeometryType()) OVER (ORDER BY ID) AS NextType
FROM TestGeospatialMethods3_STGeometryType_GEOG_db
ORDER BY ID;
go

--  Subquery - Geometry
SELECT * FROM (
    SELECT ID, GeomColumn.STGeometryType() AS GeomType
    FROM TestGeospatialMethods3_STGeometryType_GEOM_db
) AS Sub
WHERE GeomType = 'Polygon'
ORDER BY ID;
go

-- 20. CASE - Geometry
SELECT ID,
    CASE GeomColumn.STGeometryType()
        WHEN 'Point' THEN 'Zero Dimensional'
        WHEN 'LineString' THEN 'One Dimensional'
        WHEN 'Polygon' THEN 'Two Dimensional'
        ELSE 'Unknown'
    END AS DimensionType
FROM TestGeospatialMethods3_STGeometryType_GEOM_db
ORDER BY ID;
go

--  CTE + Window Combined - Geometry
WITH RankedGeom AS (
    SELECT ID, GeomColumn.STGeometryType() AS GeomType,
           ROW_NUMBER() OVER (ORDER BY GeomColumn.STGeometryType(), ID) AS RowNum,
           COUNT(*) OVER (PARTITION BY GeomColumn.STGeometryType()) AS TypeCount
    FROM TestGeospatialMethods3_STGeometryType_GEOM_db
)
SELECT * FROM RankedGeom ORDER BY RowNum;
go

--  WHERE + GROUP BY + ORDER BY Combined
SELECT GeomColumn.STGeometryType() AS GeomType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOM_db
WHERE GeomColumn.STGeometryType() != 'Point'
GROUP BY GeomColumn.STGeometryType()
ORDER BY TypeCount DESC, GeomType ASC;
go

-- View WHERE
SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOM_View_db
WHERE GeomType = 'Point'
ORDER BY ID;
go

SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOG_View_db
WHERE GeogType = 'Polygon'
ORDER BY ID;
go

-- View ORDER BY
SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOM_View_db
ORDER BY GeomType ASC, ID ASC;
go

-- View GROUP BY
SELECT GeomType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOM_View_db
GROUP BY GeomType
ORDER BY GeomType;
go

SELECT GeogType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOG_View_db
GROUP BY GeogType
ORDER BY GeogType;
go

-- View Subquery
SELECT * FROM (
    SELECT ID, GeomType FROM TestGeospatialMethods3_STGeometryType_GEOM_View_db
) AS Sub
WHERE GeomType = 'Polygon'
ORDER BY ID;
go


-- MASTER DATABASE TESTS

USE MASTER;
go

-- Inline Geometry Tests
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

-- Inline Geography Tests
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

-- Table SELECT / WHERE / GROUP BY - Geometry
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

-- Table SELECT / WHERE / GROUP BY - Geography
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

-- View Tests
SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOM_View_Temp ORDER BY ID;
go

SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOG_View_Temp ORDER BY ID;
go

-- Variable Tests
DECLARE @geom geometry = geometry::STGeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))', 4326);
SELECT @geom.STGeometryType();
go

DECLARE @geog geography = geography::STGeomFromText('LINESTRING(-122.36 47.65, -122.34 47.66)', 4326);
SELECT @geog.STGeometryType();
go

-- Combined with STDimension
SELECT GeomColumn.STGeometryType() AS GeomType, GeomColumn.STDimension() AS Dimension
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
ORDER BY ID;
go

SELECT GeogColumn.STGeometryType() AS GeogType, GeogColumn.STDimension() AS Dimension
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp
ORDER BY ID;
go

-- Combined with STIsEmpty
SELECT GeomColumn.STGeometryType() AS GeomType, GeomColumn.STIsEmpty() AS IsEmpty
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
ORDER BY ID;
go

SELECT GeogColumn.STGeometryType() AS GeogType, GeogColumn.STIsEmpty() AS IsEmpty
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp
ORDER BY ID;
go

-- Different SRIDs
SELECT geometry::STGeomFromText('POINT(1 2)', 0).STGeometryType();
go

SELECT geography::STGeomFromText('POINT(-122.34 47.65)', 4269).STGeometryType();
go

-- NULL Tests
DECLARE @nullGeom geometry = NULL;
SELECT @nullGeom.STGeometryType();
go

DECLARE @nullGeog geography = NULL;
SELECT @nullGeog.STGeometryType();
go

-- ORDER BY on function result
SELECT ID, GeomColumn.STGeometryType() AS GeometryType
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
ORDER BY GeomColumn.STGeometryType(), ID;
go

-- CASE Statement
SELECT ID,
    CASE GeomColumn.STGeometryType()
        WHEN 'Point' THEN 'Zero Dimensional'
        WHEN 'LineString' THEN 'One Dimensional'
        WHEN 'Polygon' THEN 'Two Dimensional'
        ELSE 'Unknown'
    END AS DimensionType
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
ORDER BY ID;
go

-- Subquery
SELECT * FROM (
    SELECT ID, GeomColumn.STGeometryType() AS GeomType
    FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
) AS SubQuery
WHERE GeomType = 'Point'
ORDER BY ID;
go

-- JOIN Geometry to Geography
SELECT g.ID AS GeomID, geo.ID AS GeogID,
       g.GeomColumn.STGeometryType() AS GeomType,
       geo.GeogColumn.STGeometryType() AS GeogType
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp g
JOIN TestGeospatialMethods3_STGeometryType_GEOG_Temp geo ON g.ID = geo.ID
ORDER BY g.ID;
go

-- Edge Cases: Z, ZM, extreme coordinates
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

-- First 3 chars should NOT be 'ST_'

DECLARE @pt geometry = geometry::STGeomFromText('POINT(1 2)', 4326);
DECLARE @ln geometry = geometry::STGeomFromText('LINESTRING(0 0, 1 1)', 4326);
DECLARE @pg geometry = geometry::STGeomFromText('POLYGON((0 0, 4 0, 4 4, 0 4, 0 0))', 4326);

SELECT 'Point' AS Type,
       @pt.STGeometryType() AS ReturnedValue,
       CASE WHEN LEFT(@pt.STGeometryType(), 3) = 'ST_' THEN 'FAIL' ELSE 'PASS' END AS PrefixCheck
UNION ALL
SELECT 'LineString',
       @ln.STGeometryType(),
       CASE WHEN LEFT(@ln.STGeometryType(), 3) = 'ST_' THEN 'FAIL' ELSE 'PASS' END
UNION ALL
SELECT 'Polygon',
       @pg.STGeometryType(),
       CASE WHEN LEFT(@pg.STGeometryType(), 3) = 'ST_' THEN 'FAIL' ELSE 'PASS' END
ORDER BY Type;
go

-- Geography: Verify no ST_ prefix on all types
DECLARE @gpt geography = geography::STGeomFromText('POINT(-122.34 47.65)', 4326);
DECLARE @gln geography = geography::STGeomFromText('LINESTRING(-122.36 47.65, -122.34 47.66)', 4326);
DECLARE @gpg geography = geography::STGeomFromText('POLYGON((-122.35 47.64, -122.33 47.64, -122.33 47.66, -122.35 47.66, -122.35 47.64))', 4326);

SELECT 'Point' AS Type,
       @gpt.STGeometryType() AS ReturnedValue,
       CASE WHEN LEFT(@gpt.STGeometryType(), 3) = 'ST_' THEN 'FAIL' ELSE 'PASS' END AS PrefixCheck
UNION ALL
SELECT 'LineString',
       @gln.STGeometryType(),
       CASE WHEN LEFT(@gln.STGeometryType(), 3) = 'ST_' THEN 'FAIL' ELSE 'PASS' END
UNION ALL
SELECT 'Polygon',
       @gpg.STGeometryType(),
       CASE WHEN LEFT(@gpg.STGeometryType(), 3) = 'ST_' THEN 'FAIL' ELSE 'PASS' END
ORDER BY Type;
go


-- Verify no row in table has ST_ prefix in result
SELECT ID, GeomColumn.STGeometryType() AS GeomType
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
WHERE GeomColumn.STGeometryType() LIKE 'ST[_]%'
ORDER BY ID;
go


SELECT ID, GeogColumn.STGeometryType() AS GeogType
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp
WHERE GeogColumn.STGeometryType() LIKE 'ST[_]%'
ORDER BY ID;
go


-- NEGATIVE CHECK: Verify ST_ prefix is NOT returned
SELECT 'BUG: ST_ prefix not stripped' AS Result
WHERE geometry::STGeomFromText('POINT(1 2)', 4326).STGeometryType() LIKE 'ST[_]%';
go

SELECT 'BUG: ST_ prefix not stripped' AS Result
WHERE geography::STGeomFromText('POINT(-122.34 47.65)', 4326).STGeometryType() LIKE 'ST[_]%';
go


-- View WHERE
SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOM_View_Temp
WHERE GeomType = 'Point'
ORDER BY ID;
go

-- View GROUP BY
SELECT GeomType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOM_View_Temp
GROUP BY GeomType
ORDER BY GeomType;
go

-- UNION ALL geometry + geography
DECLARE @geom geometry = geometry::STGeomFromText('LINESTRING(0 0, 10 10)', 4326);
DECLARE @geog geography = geography::STGeomFromText('POINT(-122.34 47.65)', 4326);
SELECT 'Geometry' AS Source, @geom.STGeometryType() AS Type
UNION ALL
SELECT 'Geography', @geog.STGeometryType();
ORDER BY Source;
go

-- SRID 999999
SELECT geometry::STGeomFromText('POINT(1 2)', 999999).STGeometryType();
go
