--Makevalid-functions-test
USE TestSpatialFunc3_DB;
go


-- VIEW SELECT

SELECT * FROM TestSpatialFunc3_GeomMetrics_MakeValid_View ORDER BY ID;
go

SELECT * FROM TestSpatialFunc3_GeogMetrics_MakeValid_View ORDER BY ID;
go

SELECT * FROM TestSpatialFunc3_GeomMetrics_Area_View ORDER BY ID;
go

SELECT * FROM TestSpatialFunc3_GeogMetrics_Area_View ORDER BY ID;
go

-- WHERE CLAUSE

SELECT ID, GeomID, GeomData.STIsValid() AS BeforeValid,
       GeomData.MakeValid().STIsValid() AS AfterValid
FROM TestSpatialFunc3_GeomMetrics
WHERE GeomData.STIsValid() = 0
ORDER BY ID;
go


SELECT * FROM TestSpatialFunc3_GeomMetrics_MakeValid_View
WHERE IsValidBefore = 0
ORDER BY ID;
go

SELECT * FROM TestSpatialFunc3_GeomMetrics_MakeValid_View
WHERE TypeAfter = 'Point'
ORDER BY ID;
go

-- ORDER BY
SELECT ID, GeomData.MakeValid().STArea() AS AreaAfter
FROM TestSpatialFunc3_GeomMetrics
WHERE GeomData IS NOT NULL
ORDER BY GeomData.MakeValid().STArea() DESC;
go

SELECT * FROM TestSpatialFunc3_GeomMetrics_Area_View
ORDER BY AreaAfter DESC;
go

SELECT * FROM TestSpatialFunc3_GeogMetrics_Area_View
ORDER BY AreaAfter DESC;
go

-- GROUP BY
SELECT GeomData.STIsValid() AS IsValid, COUNT(*) AS Cnt
FROM TestSpatialFunc3_GeomMetrics
WHERE GeomData IS NOT NULL
GROUP BY GeomData.STIsValid()
ORDER BY IsValid;
go

SELECT GeomID, COUNT(*) AS Cnt,
       SUM(CAST(GeomData.MakeValid().STArea() AS FLOAT)) AS TotalArea
FROM TestSpatialFunc3_GeomMetrics
WHERE GeomData IS NOT NULL
GROUP BY GeomID
ORDER BY GeomID;
go

-- JOIN

SELECT g.ID AS GeomRowID, gg.ID AS GeogRowID,
       g.GeomID, g.GeomData.MakeValid().STIsValid() AS GeomValid,
       gg.GeogData.MakeValid().STIsValid() AS GeogValid
FROM TestSpatialFunc3_GeomMetrics g
JOIN TestSpatialFunc3_GeogMetrics gg ON g.GeomID = gg.GeogID
WHERE g.GeomData IS NOT NULL AND gg.GeogData IS NOT NULL
ORDER BY g.ID, gg.ID;
go

SELECT gv.ID, gv.TypeAfter AS GeomType, ggv.TypeAfter AS GeogType
FROM TestSpatialFunc3_GeomMetrics_MakeValid_View gv
JOIN TestSpatialFunc3_GeogMetrics_MakeValid_View ggv ON gv.ID = ggv.ID
WHERE gv.IsValidAfter IS NOT NULL AND ggv.IsValidAfter IS NOT NULL
ORDER BY gv.ID;
go


SELECT v.ID, v.TypeAfter, g.MetricValue
FROM TestSpatialFunc3_GeomMetrics_MakeValid_View v
JOIN TestSpatialFunc3_GeomMetrics g ON v.ID = g.ID
ORDER BY v.ID;
go


-- CTE

-- CTE from view
WITH ViewCTE AS (
    SELECT ID, TypeAfter, IsValidAfter
    FROM TestSpatialFunc3_GeomMetrics_MakeValid_View
    WHERE IsValidBefore IS NOT NULL
)
SELECT * FROM ViewCTE WHERE TypeAfter = 'Point' ORDER BY ID;
go

-- LAG/LEAD on validity
SELECT ID, GeomData.STIsValid() AS IsValid,
       LAG(GeomData.STIsValid()) OVER (ORDER BY ID) AS PrevValid,
       LEAD(GeomData.STIsValid()) OVER (ORDER BY ID) AS NextValid
FROM TestSpatialFunc3_GeomMetrics
WHERE GeomData IS NOT NULL
ORDER BY ID;
go

-- NESTED FUNCTIONS

SELECT ID, GeomData.MakeValid().STIsValid() AS AlwaysValid
FROM TestSpatialFunc3_GeomMetrics
WHERE GeomData IS NOT NULL
ORDER BY ID;
go

-- =============================================
-- CASE STATEMENT
-- =============================================

SELECT ID,
    CASE
        WHEN GeomData.MakeValid().STArea() > 50 THEN 'Large'
        WHEN GeomData.MakeValid().STArea() > 0 THEN 'Small'
        ELSE 'No Area'
    END AS SizeCategory
FROM TestSpatialFunc3_GeomMetrics
WHERE GeomData IS NOT NULL
ORDER BY ID;
go

USE MASTER;

--NULL geometry

DECLARE @g geometry;
SET @g = NULL;
SELECT @g.MakeValid() AS result;
go

--EMPTY geometry
DECLARE @g geometry;
SET @g = geometry::STGeomFromText('POINT EMPTY', 0);
SELECT @g.MakeValid().STAsText() AS result;
go

DECLARE @g geometry;
SET @g = geometry::STGeomFromText('POLYGON EMPTY', 0);
SELECT @g.MakeValid().STAsText() AS result;
go

--with valid point
DECLARE @g geometry;
SET @g = geometry::STGeomFromText('POINT(10 20)', 0);
SELECT @g.MakeValid().STAsText() AS result, @g.MakeValid().STIsValid() AS is_valid;
go

DECLARE @g geometry;
SET @g = geometry::STGeomFromText('POINT(10 20)', 4326);
SELECT @g.MakeValid().STAsText() AS result, @g.MakeValid().STSrid AS srid;
go

--valid polygon
DECLARE @g geometry;
SET @g = geometry::STGeomFromText('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))', 0);
SELECT @g.MakeValid().STAsText() AS result, @g.MakeValid().STIsValid() AS is_valid;
go

-- self-intersecting polygon
DECLARE @g geometry;
SET @g = geometry::STGeomFromText('POLYGON((0 0, 10 10, 10 0, 0 10, 0 0))', 0);
SELECT @g.STIsValid() AS before_valid, @g.MakeValid().STIsValid() AS after_valid;
go

--complex self-intersecting polygon
DECLARE @g geometry;
SET @g = geometry::STGeomFromText('POLYGON((0 0, 5 5, 10 0, 10 10, 5 5, 0 10, 0 0))', 0);
SELECT @g.STIsValid() AS before_valid, @g.MakeValid().STIsValid() AS after_valid;
go

DECLARE @g geometry;
SET @g = geometry::STGeomFromText('LINESTRING(0 0, 10 10, 20 20, 30 10)', 0);
SELECT @g.MakeValid().STAsText() AS result, @g.MakeValid().STIsValid() AS is_valid;
go

DECLARE @g geometry;
SET @g = geometry::STGeomFromText('POLYGON((0 0, 10 10, 10 0, 0 10, 0 0))', 4326);
SELECT @g.STSrid AS original_srid, @g.MakeValid().STSrid AS fixed_srid;
go

DECLARE @g geometry;
SET @g = geometry::STGeomFromText('POLYGON((0 0, 10 10, 10 0, 0 10, 0 0))', 0);
SELECT @g.MakeValid().STArea() AS area;
go

DECLARE @g geometry;
SET @g = geometry::Point(10, 20, 0);
SELECT @g.MakeValid().STAsText() AS result, @g.MakeValid().STIsValid() AS is_valid;
go

DECLARE @g geometry;
SET @g = geometry::STGeomFromText('POLYGON((0 0, 10 10, 10 0, 0 10, 0 0))', 0);
SELECT @g . MakeValid ( ) . STIsValid ( ) AS is_valid;
go

--Test chained MakeValid calls
DECLARE @g geometry;
SET @g = geometry::STGeomFromText('POLYGON((0 0, 10 10, 10 0, 0 10, 0 0))', 0);
SELECT @g.MakeValid().MakeValid().STIsValid() AS is_valid;
go

-- Geography tests start here

-- Test MakeValid with NULL geography
DECLARE @g geography;
SET @g = NULL;
SELECT @g.MakeValid() AS result;
go

-- Test MakeValid with empty geography 
DECLARE @g geography;
SET @g = geography::STGeomFromText('POINT EMPTY', 4326);
SELECT @g.MakeValid().STAsText() AS result;
go

DECLARE @g geography;
SET @g = geography::STGeomFromText('POLYGON EMPTY', 4326);
SELECT @g.MakeValid().STAsText() AS result;
go

-- Test MakeValid with valid geography point
DECLARE @g geography;
SET @g = geography::STGeomFromText('POINT(-122.349 47.651)', 4326);
SELECT @g.MakeValid().STAsText() AS result, @g.MakeValid().STIsValid() AS is_valid;
go

DECLARE @g geography;
SET @g = geography::Point(47.651, -122.349, 4326);
SELECT @g.MakeValid().STAsText() AS result, @g.MakeValid().STIsValid() AS is_valid;
go

-- Test MakeValid with valid geography polygon
DECLARE @g geography;
SET @g = geography::STGeomFromText('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))', 4326);
SELECT @g.MakeValid().STAsText() AS result, @g.MakeValid().STIsValid() AS is_valid;
go

-- Test MakeValid with invalid geography polygon
DECLARE @g geography;
SET @g = geography::STGeomFromText('POLYGON((0 0, 10 10, 10 0, 0 10, 0 0))', 4326);
SELECT @g.STIsValid() AS before_valid, @g.MakeValid().STIsValid() AS after_valid;
go

-- Test MakeValid with complex invalid geography polygon
DECLARE @g geography;
SET @g = geography::STGeomFromText('POLYGON((0 0, 5 5, 10 0, 10 10, 5 5, 0 10, 0 0))', 4326);
SELECT @g.STIsValid() AS before_valid, @g.MakeValid().STIsValid() AS after_valid;
go

-- Test MakeValid with geography area calculation
DECLARE @g geography;
SET @g = geography::STGeomFromText('POLYGON((0 0, 10 10, 10 0, 0 10, 0 0))', 4326);
SELECT @g.MakeValid().STArea() AS area;
go


DECLARE @g geography;
SET @g = geography::STGeomFromText('POLYGON((0 0, 10 10, 10 0, 0 10, 0 0))', 4326);
SELECT @g . MakeValid ( ) . STIsValid ( ) AS is_valid;
go

-- Test chained MakeValid calls on geography
DECLARE @g geography;
SET @g = geography::STGeomFromText('POLYGON((0 0, 10 10, 10 0, 0 10, 0 0))', 4326);
SELECT @g.MakeValid().MakeValid().STIsValid() AS is_valid;
go

-- Table-based tests for geometry
SELECT ID, Description, GeomColumn.MakeValid().STAsText() AS MadeValid FROM TestSpatialFunc3_MakeValidGeomTemp ORDER BY ID;
go

SELECT ID, Description, GeomColumn.STIsValid() AS BeforeValid, GeomColumn.MakeValid().STIsValid() AS AfterValid FROM TestSpatialFunc3_MakeValidGeomTemp ORDER BY ID;
go

SELECT ID, Description, GeomColumn.MakeValid().STArea() AS Area FROM TestSpatialFunc3_MakeValidGeomTemp ORDER BY ID;
go

SELECT ID, Description, GeomColumn.STSrid AS BeforeSRID, GeomColumn.MakeValid().STSrid AS AfterSRID FROM TestSpatialFunc3_MakeValidGeomTemp ORDER BY ID;
go

SELECT ID, Description, GeomColumn.MakeValid().STIsEmpty() AS IsEmpty FROM TestSpatialFunc3_MakeValidGeomTemp ORDER BY ID;
go

SELECT ID, Description, GeomColumn.MakeValid().STDimension() AS Dimension FROM TestSpatialFunc3_MakeValidGeomTemp ORDER BY ID;
go

-- Table-based tests for geography
SELECT ID, Description, GeogColumn.MakeValid().STAsText() AS MadeValid FROM TestSpatialFunc3_MakeValidGeogTemp ORDER BY ID;
go

SELECT ID, Description, GeogColumn.STIsValid() AS BeforeValid, GeogColumn.MakeValid().STIsValid() AS AfterValid FROM TestSpatialFunc3_MakeValidGeogTemp ORDER BY ID;
go

SELECT ID, Description, GeogColumn.MakeValid().STArea() AS Area FROM TestSpatialFunc3_MakeValidGeogTemp ORDER BY ID;
go

SELECT ID, Description, GeogColumn.MakeValid().STIsEmpty() AS IsEmpty FROM TestSpatialFunc3_MakeValidGeogTemp ORDER BY ID;
go

SELECT ID, Description, GeogColumn.MakeValid().STDimension() AS Dimension FROM TestSpatialFunc3_MakeValidGeogTemp ORDER BY ID;
go

-- View-based tests
SELECT * FROM TestSpatialFunc3_MakeValidGeomView1 ORDER BY ID;
go

SELECT * FROM TestSpatialFunc3_MakeValidGeomView2 ORDER BY ID;
go

SELECT * FROM TestSpatialFunc3_MakeValidGeomView3 ORDER BY ID;
go

SELECT * FROM TestSpatialFunc3_MakeValidGeomView5 ORDER BY ID;
go

SELECT * FROM TestSpatialFunc3_MakeValidGeogView1 ORDER BY ID;
go

SELECT * FROM TestSpatialFunc3_MakeValidGeogView2 ORDER BY ID;
go

SELECT * FROM TestSpatialFunc3_MakeValidGeogView3 ORDER BY ID;
go

DECLARE @nullGeom geometry;
DECLARE @validGeom geometry = geometry::STGeomFromText('POLYGON((0 0, 10 10, 10 0, 0 10, 0 0))', 0);
SELECT 'MakeValid NULL' AS Test, @nullGeom.MakeValid() AS Result;
SELECT 'MakeValid Valid' AS Test, @validGeom.MakeValid().STIsValid() AS Result;
go

DECLARE @nullGeog geography;
DECLARE @validGeog geography = geography::STGeomFromText('POLYGON((0 0, 10 10, 10 0, 0 10, 0 0))', 4326);
SELECT 'MakeValid NULL' AS Test, @nullGeog.MakeValid() AS Result;
SELECT 'MakeValid Valid' AS Test, @validGeog.MakeValid().STIsValid() AS Result;
go

-- Test MakeValid on invalid geometry records only
SELECT ID, Description, GeomColumn.STIsValid() AS BeforeValid, GeomColumn.MakeValid().STIsValid() AS AfterValid 
FROM TestSpatialFunc3_MakeValidGeomTemp 
WHERE GeomColumn.STIsValid() = 0 
ORDER BY ID;
go

-- Test MakeValid on valid geometry records only
SELECT ID, Description, GeomColumn.MakeValid().STAsText() AS MadeValid 
FROM TestSpatialFunc3_MakeValidGeomTemp 
WHERE GeomColumn.STIsValid() = 1 
ORDER BY ID;
go

-- Test MakeValid on NULL geometry records
SELECT ID, Description, GeomColumn.MakeValid() AS MadeValid 
FROM TestSpatialFunc3_MakeValidGeomTemp 
WHERE GeomColumn IS NULL 
ORDER BY ID;
go

-- Test MakeValid on invalid geography records only
SELECT ID, Description, GeogColumn.STIsValid() AS BeforeValid, GeogColumn.MakeValid().STIsValid() AS AfterValid 
FROM TestSpatialFunc3_MakeValidGeogTemp 
WHERE GeogColumn.STIsValid() = 0 
ORDER BY ID;
go

SELECT ID, Description, GeogColumn.MakeValid().STAsText() AS MadeValid 
FROM TestSpatialFunc3_MakeValidGeogTemp 
WHERE GeogColumn.STIsValid() = 1 
ORDER BY ID;
GO

-- Edge case tests

-- Test MakeValid with duplicate points in linestring
DECLARE @g geometry = geometry::STGeomFromText('LINESTRING(0 0, 0 0, 10 10, 10 10, 20 20)', 0);
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with self-intersecting linestring
DECLARE @g geometry = geometry::STGeomFromText('LINESTRING(0 0, 10 10, 10 0, 0 10)', 0);
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with polygon containing disconnected hole
DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0), (20 20, 20 25, 25 25, 25 20, 20 20))', 0);
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with overlapping holes in polygon
DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 0 20, 20 20, 20 0, 0 0), (2 2, 2 10, 10 10, 10 2, 2 2), (5 5, 5 15, 15 15, 15 5, 5 5))', 0);
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with valid polygon containing hole
DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 0 20, 20 20, 20 0, 0 0), (5 5, 15 5, 15 15, 5 15, 5 5))', 0);
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with polygon having spike
DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 10 0, 10 10, 5 5.0001, 10 10, 0 10, 0 0))', 0);
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with degenerate 
DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 10 0, 10 0, 0 0))', 0);
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('LINESTRING(5 5, 5 5)', 0);
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with 3D point
DECLARE @g geometry = geometry::STGeomFromText('POINT(10 20 30)', 0);
SELECT @g.MakeValid().STAsText(), @g.MakeValid().HasZ;
go

-- Test MakeValid with point having M coordinate
DECLARE @g geometry = geometry::STGeomFromText('POINT(10 20 NULL 40)', 0);
SELECT @g.MakeValid().STAsText(), @g.MakeValid().HasM;
go

-- Test MakeValid with 3D linestring
DECLARE @g geometry = geometry::STGeomFromText('LINESTRING(0 0 0, 10 10 10, 20 20 20)', 0);
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with 3D polygon
DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0 0, 10 10 10, 10 0 5, 0 10 5, 0 0 0))', 0);
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with very large coordinates
DECLARE @g geometry = geometry::STGeomFromText('POINT(1000000000 1000000000)', 0);
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with very small coordinates
DECLARE @g geometry = geometry::STGeomFromText('POINT(0.000000001 0.000000001)', 0);
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with all negative coordinates
DECLARE @g geometry = geometry::STGeomFromText('POLYGON((-10 -10, -10 10, 10 10, 10 -10, -10 -10))', 0);
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('POLYGON((-5 -5, -5 5, 5 5, 5 -5, -5 -5))', 0);
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with polygon of identical points
DECLARE @g geometry = geometry::STGeomFromText('POLYGON((5 5, 5 5, 5 5, 5 5))', 0);
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with polygon having repeated vertex
DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 5 0, 10 0, 5 0, 0 0))', 0);
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with simple valid polygon
DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))', 0); 
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with complex self-intersecting polygon
DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 5 10, 10 0, 10 10, 5 10, 0 10, 0 0))', 0);
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with nearly closed polygon
DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 0 10, 10 10, 10 0.0000001, 10 0, 0 0))', 0);
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with geography crossing dateline
DECLARE @g geography = geography::STGeomFromText('LINESTRING(170 0, -170 0)', 4326);
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with geography near pole
DECLARE @g geography = geography::Point(89.999, 0, 4326);
SELECT @g.MakeValid().STAsText();
go

-- Test MakeValid with inline geometry construction
SELECT geometry::STGeomFromText('POLYGON((0 0,10 10,10 0,0 10,0 0))', 0).MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 0 20, 20 20, 20 0, 0 0), (5 5, 15 5, 15 15, 5 15, 5 5))', 0);
SELECT @g.MakeValid().STAsText();
go

-- CTE with MakeValid validation
WITH ValidGeometries AS (
    SELECT ID, Description, 
           GeomColumn.MakeValid() AS ValidGeom,
           GeomColumn.STIsValid() AS OriginalValid,
           GeomColumn.MakeValid().STIsValid() AS MadeValid
    FROM TestSpatialFunc3_MakeValidGeomTemp
    WHERE GeomColumn IS NOT NULL
)
SELECT ID, Description, OriginalValid, MadeValid,
       ValidGeom.STAsText() AS ValidGeomText
FROM ValidGeometries
WHERE OriginalValid = 0
ORDER BY ID;
go

-- Window functions with MakeValid
SELECT ID, Description,
       GeomColumn.MakeValid().STArea() AS Area,
       ROW_NUMBER() OVER (ORDER BY GeomColumn.MakeValid().STArea() DESC) AS AreaRank
FROM TestSpatialFunc3_MakeValidGeomTemp
WHERE GeomColumn IS NOT NULL AND GeomColumn.MakeValid().STArea() > 0
ORDER BY AreaRank;
go

--boundary testcases
DECLARE @g geometry = geometry::STGeomFromText('POINT(-180 -90)', 4326);
SELECT @g.MakeValid().STAsText() AS BoundaryPoint;
go

DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 1 0, 0 0, 0 0))', 0);
SELECT @g.MakeValid().STArea() AS ZeroArea;
go

-- Error Handling Tests

DECLARE @g geometry;
BEGIN TRY
    SET @g = geometry::STGeomFromText('INVALID_GEOMETRY', 0);
    SELECT @g.MakeValid().STAsText() AS Result;
END TRY
BEGIN CATCH
    SELECT 'Error handled' AS Result;
END CATCH;
go

DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10.0000000001, 0 0))', 0);
SELECT @g.MakeValid().STIsValid() AS TinyDifferenceValid;
go

SELECT * FROM TestSpatialFunc3_MakeValidGeomView4 ORDER BY ID;
go

