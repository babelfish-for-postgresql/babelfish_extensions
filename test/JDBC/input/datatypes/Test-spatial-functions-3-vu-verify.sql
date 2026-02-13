--Parse

DECLARE @geomText NVARCHAR(MAX);
SET @geomText = 'POINT(1.0 2.0)';
SELECT geometry::Parse(@geomText).STAsText() AS ParsedGeometry;
go

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

DECLARE @geomText NVARCHAR(MAX);
SET @geomText = 'POINT(-122.34900 47.65100)';
SELECT geometry::Parse(@geomText).STAsText() AS ParsedGeometry;
go

DECLARE @geogText NVARCHAR(MAX);
SET @geogText = 'POINT(-122.34900 47.65100)';
SELECT geography::Parse(@geogText).STAsText() AS ParsedGeography;
go

SELECT ID, geometry::Parse(GeomColumn.STAsText()).STAsText() AS ParsedGeom FROM TestGeospatialParse_GeomTemp3 ORDER BY ID;
go

SELECT ID, geography::Parse(GeogColumn.STAsText()).STAsText() AS ParsedGeog FROM TestGeospatialParse_GeogTemp ORDER BY ID;
go

DECLARE @searchText NVARCHAR(MAX);
SET @searchText = 'POINT(3.0 4.0)';
SELECT ID FROM TestGeospatialParse_GeomTemp3 WHERE geometry::Parse(@searchText).STEquals(GeomColumn) = 1 ORDER BY ID;
go

DECLARE @searchText NVARCHAR(MAX);
SET @searchText = 'POINT(3.0 4.0)';
SELECT ID FROM TestGeospatialParse_GeogTemp WHERE geography::Parse(@searchText).STEquals(GeogColumn) = 1 ORDER BY ID;
go

DECLARE @refText NVARCHAR(MAX);
SET @refText = 'POINT(3.0 4.0)';
SELECT g1.ID, g2.ID FROM TestGeospatialParse_GeomTemp3 g1 
JOIN TestGeospatialParse_GeomTemp3 g2 ON geometry::Parse(@refText).STIntersects(g1.GeomColumn) = 1 
ORDER BY g1.ID, g2.ID;
go

DECLARE @testText NVARCHAR(MAX);
SET @testText = 'POINT(1.0 2.0)';
SELECT ID, 
CASE WHEN geometry::Parse(@testText).STDistance(GeomColumn) < 5.0 THEN 'Near' ELSE 'Far' END AS Proximity
FROM TestGeospatialParse_GeomTemp3 ORDER BY ID;
go

DECLARE @refText NVARCHAR(MAX);
SET @refText = 'POINT(3.0 4.0)';
WITH ParseCTE AS (
    SELECT ID, geometry::Parse(@refText).STDistance(GeomColumn) AS Distance 
    FROM TestGeospatialParse_GeomTemp3
)
SELECT * FROM ParseCTE WHERE Distance < 10.0 ORDER BY Distance;
go

DECLARE @refText NVARCHAR(MAX);
SET @refText = 'POINT(3.0 4.0)';
SELECT ID, geometry::Parse(@refText).STDistance(GeomColumn) AS Distance 
FROM TestGeospatialParse_DB.dbo.TestGeospatialParse_GeometryTable3ORDER BY ID;
go

DECLARE @refText NVARCHAR(MAX);
SET @refText = 'POINT(3.0 4.0)';
SELECT ID, geography::Parse(@refText).STDistance(GeogColumn) AS Distance 
FROM TestGeospatialParse_DB.dbo.TestGeospatialParse_GeographyTable3 ORDER BY ID;
go

DECLARE @nullText NVARCHAR(MAX);
SET @nullText = NULL;
SELECT geometry::Parse(@nullText) AS ParsedGeometry;
go

DECLARE @nullText NVARCHAR(MAX);
SET @nullText = NULL;
SELECT geography::Parse(@nullText) AS ParsedGeography;
go

DECLARE @nullString NVARCHAR(MAX);
SET @nullString = 'NULL';
SELECT geometry::Parse(@nullString) AS ParsedGeometry;
go

DECLARE @nullString NVARCHAR(MAX);
SET @nullString = 'NULL';
SELECT geography::Parse(@nullString) AS ParsedGeography;
go

DECLARE @emptyPoint NVARCHAR(MAX);
SET @emptyPoint = 'POINT EMPTY';
SELECT geometry::Parse(@emptyPoint).STAsText() AS ParsedGeometry;
go

DECLARE @emptyPoint NVARCHAR(MAX);
SET @emptyPoint = 'POINT EMPTY';
SELECT geography::Parse(@emptyPoint).STAsText() AS ParsedGeography;
go

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

SELECT geometry::Parse(NULL);
go

SELECT geography::Parse(NULL);
go

SELECT geometry::Parse('NULL');
go

SELECT geography::Parse('NULL');
go

SELECT geometry::Parse('  NULL   ');
go

SELECT geometry::Parse('POINT(1 2 3 4)').STAsText();
go

SELECT geography::Parse('POINT(1 2 3 4)').STAsText();
go

SELECT geometry::Parse('POINT(1 2 3)').STAsText();
go

SELECT geography::Parse('POINT(1 2 3)').STAsText();
go

SELECT geometry::Parse('POINT(1)');   
go

SELECT geography::Parse('POINT(1)').STAsText();
go

SELECT geometry::Parse('POLYGON((0 0, 1 1))');
go

SELECT geography::Parse('POLYGON((0 0, 1 1))');
go

SELECT geometry::Parse('hello');
go

SELECT geography::Parse('hello');
go

SELECT geometry::Parse('POINT(999999999 999999999)').STAsText();
go

SELECT geography::Parse('POINT(999999999 999999999)').STAsText();
go

SELECT geometry::Parse('POINT(-180 -90)').STAsText();
go

SELECT geography::Parse('POINT(-180 -90)').STAsText();
go

SELECT geometry::Parse('LINESTRING EMPTY').STAsText();
go

SELECT geometry::Parse('lineString(0 0, 1 1)').STAsText();
go

SELECT geography::Parse('LINESTRING EMPTY').STAsText();
go

SELECT geography::Parse('lineString(0 0, 1 1)').STAsText();
go

SELECT geometry::Parse('POINT(1 2)').STAsText() AS geom
UNION
SELECT geometry::Parse('POINT(3 4)').STAsText()
UNION
SELECT geometry::Parse('NULL').STAsText();
ORDER BY geom DESC;
go

SELECT GeomColumn.STGeometryType() AS GeomType, 
       COUNT(*) AS Count
FROM TestGeospatialParse_GeomTemp3
GROUP BY GeomColumn.STGeometryType()
ORDER BY GeomType;

SELECT ID, 
       geometry::Parse('POINT(0 0)').STDistance(GeomColumn) AS Distance,
       ROW_NUMBER() OVER (ORDER BY geometry::Parse('POINT(0 0)').STDistance(GeomColumn)) AS RowNum
FROM TestGeospatialParse_GeomTemp3;

SELECT CAST(geometry::Parse('POINT(1 2)').STAsText() AS VARCHAR(100)) AS Result;
go

SELECT geometry::Parse('');
go

select hierarchyid::Parse('/1/3/2/');
go

DECLARE @node hierarchyid;
SET @node = hierarchyid::Parse('/1/3/2/');
SELECT @node AS NodeValue;
go

WITH ParseCTE AS (
    SELECT 1 AS ID, geometry::Parse('POINT(1 2)').STAsText() AS GeomText
    UNION ALL
    SELECT 2, geometry::Parse('LINESTRING(0 0, 1 1)').STAsText()
    UNION ALL
    SELECT 3, geometry::Parse('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))').STAsText()
)
SELECT ID, GeomText FROM ParseCTE ORDER BY ID;
go

WITH GeogCTE AS (
    SELECT 1 AS ID, geography::Parse('POINT(-122.349 47.651)').STAsText() AS GeogText
    UNION ALL
    SELECT 2, geography::Parse('LINESTRING(-122.36 47.65, -122.34 47.66)').STAsText()
)
SELECT ID, GeogText FROM GeogCTE ORDER BY ID;
go

SELECT *, ROW_NUMBER() OVER (ORDER BY Dimension) AS RowNum FROM (
    SELECT 1 AS ID, geometry::Parse('POINT(1 2)').STDimension() AS Dimension
    UNION ALL
    SELECT 2, geometry::Parse('LINESTRING(0 0, 1 1)').STDimension()
    UNION ALL
    SELECT 3, geometry::Parse('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))').STDimension()
) AS Results;
go

SELECT sys.geometry::Parse('POINT(1 2)').STAsText() AS Result;
go

SELECT geometry::Parse('INVALID(1 2)');
go

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

SELECT geometry::Parse('POINT(1 2 3 4)');
go

SELECT geometry::Parse('LINESTRING(0 0, 1 1)');
go

SELECT geometry::Parse('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))');
go

SELECT geometry::Parse('POINT(999999999 999999999)');
go

SELECT geometry::Parse('POINT Z(1 2 3)');
go

SELECT geometry::Parse('POINT M(1 2 4)');
go

SELECT geometry::Parse('POLYGON M((0 0 0, 0 10 0, 10 10 0, 10 0 0, 0 0 0))');
go

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
