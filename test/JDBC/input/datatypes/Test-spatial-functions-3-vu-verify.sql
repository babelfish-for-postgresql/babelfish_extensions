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

SELECT ID, geography::Parse(GeogColumn.STAsText()).STAsText() AS ParsedGeog FROM TestGeospatialParse_GeogTemp ORDER BY ID;
go

-- Parse with STEquals in WHERE clause
DECLARE @searchText NVARCHAR(MAX);
SET @searchText = 'POINT(3.0 4.0)';
SELECT ID FROM TestGeospatialParse_GeomTemp3 WHERE geometry::Parse(@searchText).STEquals(GeomColumn) = 1 ORDER BY ID;
go

DECLARE @searchText NVARCHAR(MAX);
SET @searchText = 'POINT(3.0 4.0)';
SELECT ID FROM TestGeospatialParse_GeogTemp WHERE geography::Parse(@searchText).STEquals(GeogColumn) = 1 ORDER BY ID;
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
    SELECT ID, geometry::Parse(@refText).STDistance(GeomColumn) AS Distance 
    FROM TestGeospatialParse_GeomTemp3
)
SELECT * FROM ParseCTE WHERE Distance < 10.0 ORDER BY Distance;
go

-- Parse with cross-database query (geometry)
DECLARE @refText NVARCHAR(MAX);
SET @refText = 'POINT(3.0 4.0)';
SELECT ID, geometry::Parse(@refText).STDistance(GeomColumn) AS Distance 
FROM TestGeospatialParse_DB.dbo.TestGeospatialParse_GeometryTable3ORDER BY ID;
go

-- Parse with cross-database query (geography)
DECLARE @refText NVARCHAR(MAX);
SET @refText = 'POINT(3.0 4.0)';
SELECT ID, geography::Parse(@refText).STDistance(GeogColumn) AS Distance 
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
SELECT geometry::Parse('NULL').STAsText();
ORDER BY geom DESC;
go

-- GROUP BY with spatial type
SELECT GeomColumn.STGeometryType() AS GeomType, 
       COUNT(*) AS Count
FROM TestGeospatialParse_GeomTemp3
GROUP BY GeomColumn.STGeometryType()
ORDER BY GeomType;

-- Window function with Parse
SELECT ID, 
       geometry::Parse('POINT(0 0)').STDistance(GeomColumn) AS Distance,
       ROW_NUMBER() OVER (ORDER BY geometry::Parse('POINT(0 0)').STDistance(GeomColumn)) AS RowNum
FROM TestGeospatialParse_GeomTemp3;

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
