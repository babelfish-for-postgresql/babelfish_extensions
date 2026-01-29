-- This file adds tests for these functions: STDimension, STDisjoint, STIntersects, STIsClosed, STIsEmpty, STIsValid

-- STIntersects

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SELECT @point1.STIntersects(@point2) AS Intersecting;
go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point1.STIntersects(@point2) AS Intersecting;
go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 0);
SELECT @point1.STIntersects(@point2) AS Intersecting;
go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4120);
SELECT @point1 . STIntersects(@point2) AS Intersecting;
go

-- Verifying with precision
DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 999999);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 999999);
SELECT STIntersects(@point1, @point2);
go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STGeomFromText('POINT(-122.354657658684900 47.658678768678100)', 4120);
SET @point2 = geography::STGeomFromText('POINT(-122.354657658684900 47.658678768678100)', 4120);
SELECT @point1.STIntersects(@point2) AS Intersecting;
go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 0);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684000 47.658678768678100)', 0);
SELECT STIntersects(@point1, @point2);
go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SELECT @point1 . STIntersects ( @point2 );
go

-- Use in an ORDER BY Clause
SELECT PointColumn1.STIntersects(PointColumn2) AS Intersects FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
SELECT PointColumn1.STIntersects(@point1) AS Intersects FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
SELECT @point1.STIntersects(PointColumn2) AS Intersects FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

SELECT ID, PointColumn1.STIntersects(PointColumn2) AS Intersecting_points FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STIntersects(@referencePoint) AS Intersection FROM TestGeospatialMethods_DB.dbo.TestGeospatialMethods_YourTable1Temp ORDER BY PointColumn.STX;
go

-- Use in a WHERE Clause
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @doesintersect BIT = 0;
SELECT PointColumn.STSrid FROM  TestGeospatialMethods_YourTableTemp WHERE PointColumn.STIntersects(@referencePoint) = @doesintersect ORDER BY PointColumn.STSrid;
go

-- Use in a CTE (Common Table Expression)
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH IntersectCTE AS ( SELECT ID, PointColumn.STIntersects(@referencePoint) AS Intersection FROM  TestGeospatialMethods_YourTableTemp)
SELECT * FROM IntersectCTE WHERE Intersection = 1 ORDER BY Intersection;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH IntersectCTE AS ( SELECT ID, PointColumn.STIntersects(@referencePoint) AS Intersections FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX)
SELECT * FROM IntersectCTE WHERE Intersections = 1.0 ORDER BY Intersections;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH IntersectCTE AS ( SELECT ID, @referencePoint.STIntersects(PointColumn) AS Intersections FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX)
SELECT * FROM IntersectCTE WHERE Intersections != 1.0 ORDER BY Intersections;
GO

-- Use in a JOIN Operation
SELECT PointA.STAsText(),PointB.STAsText() FROM  TestGeospatialMethods_TableATemp JOIN  TestGeospatialMethods_TableBTemp ON PointA.STIntersects(TestGeospatialMethods_TableBTemp.PointB) != 1 ORDER BY PointA.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointA.STAsText(),PointB.STAsText() FROM  TestGeospatialMethods_TableATemp JOIN  TestGeospatialMethods_TableBTemp ON @referencePoint.STIntersects(TestGeospatialMethods_TableBTemp.PointB) = 1 ORDER BY PointA.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointA.STAsText(),PointB.STAsText() FROM  TestGeospatialMethods_TableATemp JOIN  TestGeospatialMethods_TableBTemp ON PointA.STIntersects(@referencePoint) != 1 ORDER BY PointA.STX;
go

-- Use in a CASE Statement
DECLARE @doesintersect BIT = 1;
SELECT ID, PointColumn1.STIntersects(PointColumn2) AS doesintersect,
CASE WHEN PointColumn1.STIntersects(PointColumn2) = @doesintersect THEN 'yes' ELSE 'no'
END AS doesintersect
FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

-- Use in a Conditional Statement
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @doesintersect BIT = 1;
SELECT ID, PointColumn.STIntersects(@referencePoint) AS IntersectingReferancePoint,
CASE WHEN PointColumn.STIntersects(@referencePoint) = @doesintersect THEN 'Close'
ELSE 'Far'
END AS Proximity
FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, @referencePoint.STIntersects(PointColumn) AS IntersectingReferancePoint,
CASE WHEN @referencePoint.STIntersects(PointColumn) = @referencePoint.STY THEN 'Close'
ELSE 'Far'
END AS Proximity
FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

-- Use in a Pivot Query
DECLARE @Ranges TABLE (MinDistance float, MaxDistance float);
INSERT INTO @Ranges VALUES (0, 5), (5, 10), (10, 15);
SELECT * FROM ( SELECT ID,
CASE WHEN PointColumn1.STIntersects(PointColumn2) BETWEEN 0 AND 1 THEN 'yes'
ELSE 'no'
END AS Range
FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX
) AS Source
PIVOT ( COUNT(ID) FOR Range IN ([0-5], [5.1-10], [10.1-15], [15.1+])) AS PivotTable;
go

-- Use in a JSON Output
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STIntersects(@referencePoint) AS Intersections,
JSON_QUERY('{"Intersections":' + CAST(PointColumn.STIntersects(@referencePoint) AS NVARCHAR(MAX)) + '}') AS Json
FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, @referencePoint.STIntersects(PointColumn) AS Intersections,
JSON_QUERY('{"Intersections":' + CAST(@referencePoint.STIntersects(PointColumn) AS NVARCHAR(MAX)) + '}') Json
FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

-- Using Square brackets '[]' identifier
SELECT [PointColumn1].STIntersects([PointColumn2]) AS Intersection FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

-- Use in Prepared Statement
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @doesintersect BIT = 1;
DECLARE @sql NVARCHAR(MAX);
DECLARE @params NVARCHAR(MAX);
SET @sql = N'
SELECT ID, PointColumn.STIntersects(@referencePoint) AS IntersectingReferancePoint,
CASE WHEN PointColumn.STIntersects(@referencePoint) = @doesintersect THEN ''Close''
ELSE ''Far''
END AS Proximity
FROM  TestGeospatialMethods_YourTableTemp
WHERE PointColumn.STIntersects(@referencePoint) = @doesintersect;';
SET @params = N'@referencePoint geometry, @doesintersect float';
EXEC sp_executesql @sql, @params, @referencePoint, @doesintersect;
go

-- Use in Multi-Part column name Statements
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STIntersects(@referencePoint) AS Intersection FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
SELECT TestGeospatialMethods_YourTableTemp.PointColumn.STIntersects(@referencePoint) AS Intersection FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
SELECT TestGeospatialMethods_YourTableTemp.PointColumn.STIntersects(@referencePoint) AS Intersection FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

-- Use in function.STIntersects(@point) Statements
DECLARE @pnt geometry;
SET @pnt = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
select geometry::Point(@pnt.STY, @pnt.STX, 4326).STIntersects(@pnt)
go

-- Use in a Group By Clause
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @intersection_points INT = 1;
SELECT ROUND(PointColumn.STIntersects(@referencePoint) / @intersection_points, 0) * @intersection_points AS Intersectinggroup,
COUNT(*) AS PointCount
FROM  TestGeospatialMethods_YourTableTemp
GROUP BY ROUND(PointColumn.STIntersects(@referencePoint) / @intersection_points, 0) * @intersection_points
ORDER BY Intersectinggroup;
go

DECLARE @referencePoint geometry = geometry::Point(1.0, 0.0, 4326);
SELECT ROUND(PointColumn.STIntersects(@referencePoint) / @referencePoint.STX, 0) * @referencePoint.STX AS Intersectinggroup,
COUNT(*) AS PointCount
FROM  TestGeospatialMethods_YourTableTemp
GROUP BY ROUND(PointColumn.STIntersects(@referencePoint) / @referencePoint.STX, 0) * @referencePoint.STX
ORDER BY Intersectinggroup;
go

-- Use in a Window Function
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn1.STIntersects(PointColumn2) AS intersection_points,
cast(PointColumn1.STIntersects(@referencePoint) as int) - LAG(PointColumn1.STIntersects(PointColumn2)) OVER (ORDER BY ID) AS Intersectinggroup 
FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STIntersects(@referencePoint) AS intersection_points,
cast(@referencePoint.STDisjoint(PointColumn) as int) - LAG(@referencePoint.STX) OVER (ORDER BY ID) AS Intersectinggroup
FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

-- Use in an UPDATE Statement
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326); 
UPDATE  TestGeospatialMethods_YourTableTemp SET PointColumn = @referencePoint
WHERE @referencePoint.STIntersects(PointColumn) = 1;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326); 
UPDATE  TestGeospatialMethods_YourTableTemp SET PointColumn = @referencePoint
WHERE PointColumn.STIntersects(@referencePoint) != 1;
go

-- Cross-database query to retrieve intersects
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STIntersects(@referencePoint) AS Intersects FROM TestGeospatialMethods_DB.dbo.TestGeospatialMethods_YourTable1Temp;
go

DECLARE @referencePoint geography = geography::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STIntersects(@referencePoint) AS Intersects FROM TestGeospatialMethods_DB.dbo.TestGeospatialMethods_YourTable3Temp;
go

SELECT 
    a.id AS id1, 
    b.id AS id2, 
    a.PointColumn.STIntersects(b.PointColumn) AS intersects
FROM 
    TestGeospatialMethods_DB.dbo.TestGeospatialMethods_YourTable1Temp a,
    dbo.TestGeospatialMethods_YourTableTemp b;
go

-- 4-part names
SELECT dbo.TestGeospatialMethods_YourTableTemp.PointColumn.STIntersects(@referencePoint) AS INTERSECTING FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

-- STDisjoint

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point1.STDisjoint(@point2) AS disjoint;
go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4204);
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4204);
SELECT @point1 . STDisjoint(@point2) AS disjoint;
go

-- Verifying with precision
DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SELECT STDisjoint(@point1, @point2);
go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geography::STPointFromText('POINT(-122.354657658684000 47.658678768678100)', 4326);
SELECT STDisjoint(@point1, @point2);
go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 0);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 0);
SELECT @point1 . STDisjoint ( @point2 );
go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STGeomFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SELECT @point1.STDisjoint(@point2);
go

-- Use in an ORDER BY Clause
SELECT ID, PointColumn1.STDisjoint(PointColumn2) AS disjoint FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
SELECT ID, PointColumn1.STDisjoint(@point1) AS disjoint FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
SELECT ID, @point1.STDisjoint(PointColumn2) AS disjoint FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

-- Use in a WHERE Clause
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @disjoint BIT = 1;
SELECT PointColumn.STAsText() FROM  TestGeospatialMethods_YourTableTemp WHERE PointColumn.STDisjoint(@referencePoint) = @disjoint ORDER BY PointColumn.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STAsText() FROM  TestGeospatialMethods_YourTableTemp WHERE @referencePoint.STDisjoint(PointColumn) = @referencePoint.STX ORDER BY PointColumn.STX;
go

SELECT ID, PointColumn1.STDisjoint(PointColumn2) AS disjoint FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STAsText() FROM  TestGeospatialMethods_YourTableTemp WHERE PointColumn.STDisjoint(@referencePoint) != @referencePoint.STX ORDER BY PointColumn.STX;
go

-- Use in a JOIN Operation
SELECT PointA.STAsText(),PointB.STAsText() FROM  TestGeospatialMethods_TableATemp JOIN  TestGeospatialMethods_TableBTemp ON PointA.STDisjoint(TestGeospatialMethods_TableBTemp.PointB) = 1 ORDER BY TestGeospatialMethods_TableBTemp.PointB.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointA.STAsText(),PointB.STAsText() FROM  TestGeospatialMethods_TableATemp JOIN  TestGeospatialMethods_TableBTemp ON @referencePoint.STDisjoint(TestGeospatialMethods_TableBTemp.PointB) = 1 ORDER BY TestGeospatialMethods_TableBTemp.PointB.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointA.STAsText(),PointB.STAsText() FROM  TestGeospatialMethods_TableATemp JOIN  TestGeospatialMethods_TableBTemp ON PointA.STDisjoint(@referencePoint) = 1 ORDER BY TestGeospatialMethods_TableBTemp.PointB.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointA.STAsText(),PointB.STAsText() FROM  TestGeospatialMethods_TableATemp JOIN  TestGeospatialMethods_TableBTemp ON TestGeospatialMethods_TableBTemp.PointB.STDisjoint(@referencePoint) = 0 ORDER BY PointB.STX;
go

-- Use in a CASE Statement
DECLARE @disjoints BIT = 1 ;
SELECT ID, PointColumn1.STDisjoint(PointColumn2) AS dodisjoint,
CASE WHEN PointColumn1.STDisjoint(PointColumn2) = @disjoints THEN 'Disjoints' ELSE 'Are_not_disjoint'
END AS Proximity
FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn1.STDisjoint(@referencePoint) AS disjoint,
CASE WHEN @referencePoint.STDisjoint(PointColumn2) = @referencePoint.STX THEN 'Disjoints' ELSE 'Are_not_disjoint'
END AS Proximity
FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

-- Use in a CTE (Common Table Expression)
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH CTE AS ( SELECT ID, PointColumn.STDisjoint(@referencePoint) AS disjoint FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX)
SELECT * FROM CTE WHERE disjoint = 1 ORDER BY disjoint;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH CTE AS ( SELECT ID, @referencePoint.STDisjoint(PointColumn) AS disjoint FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX)
SELECT * FROM CTE WHERE disjoint = 1 ORDER BY disjoint;
go

-- Use in a Conditional Statement
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @disjoints BIT = 1;
SELECT ID, PointColumn.STDisjoint(@referencePoint) AS ReferencePoint,
CASE WHEN PointColumn.STDisjoint(@referencePoint) = @disjoints THEN 'disjoint'
ELSE 'are_not_disjoint'
END AS Proximity
FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, @referencePoint.STDisjoint(PointColumn) AS ReferencePoint,
CASE WHEN @referencePoint.STDisjoint(PointColumn) = @referencePoint.STY THEN 'disjoint'
ELSE 'are_not_disjoint'
END AS Proximity
FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

-- Use in a Pivot Query
DECLARE @Ranges TABLE (MinDistance float, MaxDistance float);
INSERT INTO @Ranges VALUES (0, 5), (5, 10), (10, 15);
SELECT * FROM ( SELECT ID,
CASE WHEN PointColumn1.STDisjoint(PointColumn2) BETWEEN 0 AND 1 THEN 'disjoint'
ELSE 'do_not_disjoint'
END AS Range
FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX
) AS Source
PIVOT ( COUNT(ID) FOR Range IN ([0-5], [5.1-10], [10.1-15], [15.1+])) AS PivotTable;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STDisjoint(@referencePoint) AS disjoint FROM TestGeospatialMethods_DB.dbo.TestGeospatialMethods_YourTable1Temp ORDER BY PointColumn.STX;
go

-- Use in a JSON Output
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STDisjoint(@referencePoint) AS disjoint,
JSON_QUERY('{"Disjoint":' + CAST(PointColumn.STDisjoint(@referencePoint) AS NVARCHAR(MAX)) + '}') AS Json
FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, @referencePoint.STDisjoint(PointColumn) AS disjoint,
JSON_QUERY('{"Disjoint":' + CAST(@referencePoint.STDisjoint(PointColumn) AS NVARCHAR(MAX)) + '}') Json
FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

-- Using Square brackets '[]' identifier
SELECT [PointColumn1].STDisjoint([PointColumn2]) AS disjoint FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

-- Use in Prepared Statement
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @disjoints BIT = 1;
DECLARE @sql NVARCHAR(MAX);
DECLARE @params NVARCHAR(MAX);
SET @sql = N'
SELECT ID, PointColumn.STDisjoint(@referencePoint) AS IntersectingReferancePoint,
CASE WHEN PointColumn.STDisjoint(@referencePoint) = @disjoints THEN ''disjoints''
ELSE ''do_not_disjoint''
END AS Proximity
FROM  TestGeospatialMethods_YourTableTemp
WHERE PointColumn.STDisjoint(@referencePoint) = @disjoints;';
SET @params = N'@referencePoint geometry, @disjoints float';
EXEC sp_executesql @sql, @params, @referencePoint, @disjoints;
go

-- Use in Multi-Part column name Statements
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STDisjoint(@referencePoint) AS disjoint FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
SELECT TestGeospatialMethods_YourTableTemp.PointColumn.STDisjoint(@referencePoint) AS disjoint FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
SELECT TestGeospatialMethods_YourTableTemp.PointColumn.STDisjoint(@referencePoint) AS disjoint FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

-- Use in function.STDisjoint(@point) Statements
DECLARE @pnt geometry;
SET @pnt = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
select geometry::Point(@pnt.STY, @pnt.STX, 4326).STDisjoint(@pnt)

-- Use in a Group By Clause
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @disjoints INT = 1;
SELECT ROUND(PointColumn.STDisjoint(@referencePoint) / @disjoints, 0) * @disjoints AS Grp,
COUNT(*) AS PointCount
FROM  TestGeospatialMethods_YourTableTemp
GROUP BY ROUND(PointColumn.STDisjoint(@referencePoint) / @disjoints, 0) * @disjoints
ORDER BY Grp;
go

DECLARE @referencePoint geometry = geometry::Point(1.0, 0.0, 4326);
SELECT ROUND(PointColumn.STDisjoint(@referencePoint) / @referencePoint.STX, 0) * @referencePoint.STX AS GRP,
COUNT(*) AS PointCount
FROM  TestGeospatialMethods_YourTableTemp
GROUP BY ROUND(PointColumn.STDisjoint(@referencePoint) / @referencePoint.STX, 0) * @referencePoint.STX
ORDER BY Grp;
go

-- Use in a Window Function
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn1.STDisjoint(PointColumn2) AS disjoint,
cast(PointColumn1.STDisjoint(@referencePoint) as int) - LAG(PointColumn1.STDisjoint(PointColumn2)) OVER (ORDER BY ID) AS Difference 
FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STDisjoint(@referencePoint) AS disjoint,
cast(@referencePoint.STDisjoint(PointColumn) as int) - LAG(@referencePoint.STX) OVER (ORDER BY ID) AS Difference
FROM  TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

-- Use in an UPDATE Statement
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326); 
UPDATE  TestGeospatialMethods_YourTableTemp SET PointColumn = @referencePoint
WHERE @referencePoint.STDisjoint(PointColumn) = 1;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326); 
UPDATE  TestGeospatialMethods_YourTableTemp SET PointColumn = @referencePoint
WHERE PointColumn.STDisjoint(@referencePoint) != 1;
go

-- Cross-database query to retrieve disjoints

SELECT 
    a.id AS id1, 
    b.id AS id2, 
    a.PointColumn.STDisjoint(b.PointColumn) AS disjoints
FROM 
    TestGeospatialMethods_DB.dbo.TestGeospatialMethods_YourTable1Temp a,
    dbo.TestGeospatialMethods_YourTableTemp b;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STDisjoint(@referencePoint) AS Disjoint FROM TestGeospatialMethods_DB.dbo.TestGeospatialMethods_YourTable1Temp;
go

DECLARE @referencePoint geography = geography::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STDisjoint(@referencePoint) AS Disjoint FROM TestGeospatialMethods_DB.dbo.TestGeospatialMethods_YourTable3Temp;
go

-- 4-part names
SELECT dbo.TestGeospatialMethods_YourTableTemp.PointColumn.STDisjoint(@referencePoint) AS DISJOINTS FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

-- Tests with different set of SRIDs
DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 3857);
SELECT @point1.STIntersects(@point2) AS Intersecting;
go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 3857);
SELECT @point1.STDisjoint(@point2) AS Disjoints;
go

-- Negative test for Geospatial functions
DECLARE @point1 geometry, @point2 varchar(50), @point3 int;
SET @point1 = geometry::Point(22.34900, -47.65100, 4326);
SET @point2 = 'Test_String';
SELECT @point1.STIntersects(@point2);
SELECT @point1.STDisjoint(@point2);
go

DECLARE @point1 geography, @point2 varchar(50), @point3 int;
SET @point1 = geography::Point(22.34900, -47.65100, 4326);
SET @point2 = 'Test_String';
SELECT @point1.STIntersects(@point2);
SELECT @point1.STDisjoint(@point2);
go

-- Null test for Geospatial functions
DECLARE @point1 geography, @point2 geography, @point3 geography;
SET @point1 = geography::STPointFromText(null, 4326);
SET @point2 = geography::STGeomFromText(null, 4326);
SET @point3 = geography::Point(22.34900, -47.65100, 4326);
SELECT @point1.STIntersects(@point2);
SELECT @point3.STIntersects(@point2);
SELECT @point1.STIntersects(@point3);
SELECT @point1.STDisjoint(@point2);
SELECT @point3.STDisjoint(@point2);
SELECT @point1.STDisjoint(@point3);
go

-- not compatible with sql server as well
-- Combining geometry and geography in a single query
DECLARE @point1 geometry, @point2 geography;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point1.STDisjoint(@point2);
go

DECLARE @point1 geometry, @point2 geography;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point2.STDisjoint(@point1);
go

DECLARE @point1 geometry, @point2 geography;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point1.STIntersects(@point2);
go

DECLARE @point1 geometry, @point2 geography;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point2.STIntersects(@point1);
go

-- STDimension

DECLARE @g geometry; 
SELECT @g.STDimension(); 
go

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STDimension(@point);
go

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 0);
SELECT STDimension(@point);
go

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 999999);
SELECT STDimension(@point);
go


DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4204);
SELECT STDimension(@point);
go

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point.STDimension();
go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point.STDimension();
go

DECLARE @point geometry;
SET @point = geometry::POINT(22.34900, -47.65100, 4326);
SELECT @point . STDimension ( );
go

DECLARE @point geography;
SET @point = geography::POINT(22.34900, -47.65100, 4326);
SELECT @point . STDimension ( );
go

SELECT location.STDimension() from  TestGeospatialMethods_SPATIALPOINTGEOM_dttemp ORDER BY location.STX;
go

SELECT location.STDimension() from  TestGeospatialMethods_SPATIALPOINTGEOG_dttemp ORDER BY location.Lat;
go

DECLARE @point geometry;
SET @point = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STDimension(@point);
SELECT @point.STDimension();
go

DECLARE @point geography;
SET @point = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STDimension(@point);
SELECT @point.STDimension();
go

-- STIsEmpty

DECLARE @g geometry;  
SET @g = geometry::STGeomFromText('POINT EMPTY', 0);  
SELECT @g.STIsEmpty();
go

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 0);
SELECT STIsEmpty(@point);
go

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 999999);
SELECT STIsEmpty(@point);
go

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STIsEmpty(@point);
go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4204);
SELECT STIsEmpty(@point);
go

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point.STIsEmpty();
go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point.STIsEmpty();
go

DECLARE @point geometry;
SET @point = geometry::POINT(22.34900, -47.65100, 4326);
SELECT @point . STIsEmpty ( );
go

DECLARE @point geography;
SET @point = geography::POINT(22.34900, -47.65100, 4326);
SELECT @point . STIsEmpty ( );
go

SELECT location.STIsEmpty() from  TestGeospatialMethods_SPATIALPOINTGEOM_dttemp ORDER BY location.STX;
go

SELECT location.STIsEmpty() from  TestGeospatialMethods_SPATIALPOINTGEOG_dttemp ORDER BY location.Lat;
go

DECLARE @point geometry;
SET @point = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STIsEmpty(@point);
SELECT @point.STIsEmpty();
go

DECLARE @point geography;
SET @point = geography::Point(22.34900, -47.65100, 4326);
SELECT STIsEmpty(@point);
SELECT @point.STIsEmpty();
go

-- STIsValid

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4204);
SELECT STIsValid(@point);
go

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 0);
SELECT STIsValid(@point);
go

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 999999);
SELECT STIsValid(@point);
go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4204);
SELECT STIsValid(@point);
go

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point.STIsValid();
go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point.STIsValid();
go

DECLARE @point geometry;
SET @point = geometry::POINT(22.34900, -47.65100, 4326);
SELECT @point . STIsValid ( );
go

DECLARE @point geography;
SET @point = geography::POINT(22.34900, -47.65100, 4326);
SELECT @point . STIsValid ( );
go

SELECT location.STIsValid() FROM TestGeospatialMethods_SPATIALPOINTGEOM_dttemp ORDER BY location.STX;
go

SELECT location.STIsValid() from  TestGeospatialMethods_SPATIALPOINTGEOG_dttemp ORDER BY location.Lat;
go

DECLARE @point geometry;
SET @point = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STIsValid(@point);
SELECT @point.STIsValid();
go

DECLARE @point geography;
SET @point = geography::Point(22.34900, -47.65100, 4326);
SELECT STIsValid(@point);
SELECT @point.STIsValid();
go

-- STIsClosed

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STIsClosed(@point);
go

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 0);
SELECT STIsClosed(@point);
go

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 999999);
SELECT STIsClosed(@point);
go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4204);
SELECT STIsClosed(@point);
go

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point.STIsClosed();
go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point.STIsClosed();
go

DECLARE @point geometry;
SET @point = geometry::POINT(22.34900, -47.65100, 4326);
SELECT @point . STIsClosed ( );
go

DECLARE @point geography;
SET @point = geography::POINT(22.34900, -47.65100, 4326);
SELECT @point . STIsClosed ( );
go

SELECT location.STIsClosed() from  TestGeospatialMethods_SPATIALPOINTGEOM_dttemp ORDER BY location.STX;
go

SELECT location.STIsClosed() from  TestGeospatialMethods_SPATIALPOINTGEOG_dttemp ORDER BY location.Lat;
go

DECLARE @point geometry;
SET @point = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STIsClosed(@point);
SELECT @point.STIsClosed();
go

DECLARE @point geography;
SET @point = geography::Point(22.34900, -47.65100, 4326);
SELECT STIsClosed(@point);
SELECT @point.STIsClosed();
go

-- Check for NULL conditions
DECLARE @nullGeom geometry;
DECLARE @validGeom geometry = geometry::STGeomFromText('POINT(0 0)', 0);

-- Tests
SELECT 'STDimension' AS Test, @nullGeom.STDimension() AS Result;
SELECT 'STDisjoint' AS Test, @nullGeom.STDisjoint(@validGeom) AS Result;
SELECT 'STIntersects' AS Test, @nullGeom.STIntersects(@validGeom) AS Result;
SELECT 'STIsClosed' AS Test, @nullGeom.STIsClosed() AS Result;
SELECT 'STIsEmpty' AS Test, @nullGeom.STIsEmpty() AS Result;
SELECT 'STIsValid' AS Test, @nullGeom.STIsValid() AS Result;

-- Test with null as second argument for binary operations
SELECT 'STDisjoint (null second)' AS Test, @validGeom.STDisjoint(@nullGeom) AS Result;
SELECT 'STIntersects (null second)' AS Test, @validGeom.STIntersects(@nullGeom) AS Result;
go

DECLARE @nullGeom geography;
DECLARE @validGeom geography = geography::STGeomFromText('POINT(0 0)', 4326);

-- Tests
SELECT 'STDimension' AS Test, @nullGeom.STDimension() AS Result;
SELECT 'STDisjoint' AS Test, @nullGeom.STDisjoint(@validGeom) AS Result;
SELECT 'STIntersects' AS Test, @nullGeom.STIntersects(@validGeom) AS Result;
SELECT 'STIsClosed' AS Test, @nullGeom.STIsClosed() AS Result;
SELECT 'STIsEmpty' AS Test, @nullGeom.STIsEmpty() AS Result;
SELECT 'STIsValid' AS Test, @nullGeom.STIsValid() AS Result;

-- Test with null as second argument for binary operations
SELECT 'STDisjoint (null second)' AS Test, @validGeom.STDisjoint(@nullGeom) AS Result;
SELECT 'STIntersects (null second)' AS Test, @validGeom.STIntersects(@nullGeom) AS Result;
go

-- Nested Functions
SELECT ID, PointColumn1.STDisjoint(PointColumn2).STIsEmpty() AS disjoint FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

SELECT ID, PointColumn1.STDisjoint(PointColumn2).STIsValid() AS disjoint FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

SELECT ID, PointColumn1.STDisjoint(PointColumn2).STIsClosed() AS disjoint FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

SELECT ID, PointColumn1.STIntersects(PointColumn2).STIsEmpty() AS Intersects FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

SELECT ID, PointColumn1.STIntersects(PointColumn2).STIsValid() AS Intersects FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

SELECT ID, PointColumn1.STIntersects(PointColumn2).STIsClosed() AS Intersects FROM  TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

-- EMPTY Cases
DECLARE @g geometry;  
SET @g = geometry::STGeomFromText('POINT EMPTY', 0);  
SELECT @g.STIsValid();
go

DECLARE @g geometry;  
SET @g = geometry::STGeomFromText('POINT EMPTY', 0);  
SELECT @g.STIsClosed();
go

DECLARE @g geometry;  
SET @g = geometry::STGeomFromText('POINT EMPTY', 0);  
SELECT @g.STDimension();
go

DECLARE @g geometry;  
SET @g = geometry::STGeomFromText('POINT EMPTY', 0);  
SELECT @g.STIsEmpty();
go

DECLARE @g1 geometry, @g2 geometry;
SET @g1 = geometry::STGeomFromText('POINT EMPTY', 0);  
SET @g2 = geometry::STGeomFromText('POINT EMPTY', 0);  
SELECT @g1.STIntersects(@g2) AS Intersecting;
go

DECLARE @g1 geometry, @g2 geometry;
SET @g1 = geometry::STGeomFromText('POINT EMPTY', 0);  
SET @g2 = geometry::STGeomFromText('POINT EMPTY', 0);  
SELECT @g1.STDisjoint(@g2) AS Disjoint;
go

DECLARE @g geography;  
SET @g = geography::STGeomFromText('POINT EMPTY', 4326);  
SELECT @g.STIsValid();
go

DECLARE @g geography;  
SET @g = geography::STGeomFromText('POINT EMPTY', 4326);  
SELECT @g.STIsClosed();
go

DECLARE @g geography;  
SET @g = geography::STGeomFromText('POINT EMPTY', 4326);  
SELECT @g.STDimension();
go

DECLARE @g geography;  
SET @g = geography::STGeomFromText('POINT EMPTY', 4326);  
SELECT @g.STIsEmpty();
go

DECLARE @g1 geography, @g2 geography;
SET @g1 = geography::STGeomFromText('POINT EMPTY', 4326);  
SET @g2 = geography::STGeomFromText('POINT EMPTY', 4326);  
SELECT @g1.STIntersects(@g2) AS Intersecting;
go

DECLARE @g1 geography, @g2 geography;
SET @g1 = geography::STGeomFromText('POINT EMPTY', 4326);  
SET @g2 = geography::STGeomFromText('POINT EMPTY', 4326);  
SELECT @g1.STDisjoint(@g2) AS Disjoint;
go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT EMPTY', 4326);
SELECT STIsClosed(@point);
go

-- Tests for CAST from CHAR/VARCHAR with EMPTY instances

Select CAST(CAST('POINT EMPTY' as varchar(100)) AS geography).STAsText();
go

Select CAST(CAST('POINT EMPTY' as char(100)) AS geography).STAsText();
go

-- Reduce 
DECLARE @line1 geometry = geometry::STGeomFromText('LINESTRING(0 0, 1 1, 2 0, 3 1, 4 0)', 0);
DECLARE @reduced1 geometry = @line1.Reduce(0.5);
SELECT @reduced1.STIsValid() AS IsValid, @reduced1.STIsEmpty() AS IsEmpty;
go

DECLARE @poly1 geometry = geometry::STGeomFromText('POLYGON((0 0, 0 1, 0.5 1.1, 1 1, 1 0, 0 0))', 0);
DECLARE @reduced2 geometry = @poly1.Reduce(0.2);
SELECT @reduced2.STIsValid() AS IsValid, @reduced2.STIsEmpty() AS IsEmpty;
GO

DECLARE @point1 geometry = geometry::STGeomFromText('POINT(5 5)', 0);
DECLARE @reduced3 geometry = @point1.Reduce(1.0);
SELECT @point1.STEquals(@reduced3) AS ShouldBeEqual;
go

DECLARE @line2 geometry = geometry::STGeomFromText('LINESTRING(0 0, 1 1, 2 0)', 0);
DECLARE @reduced4 geometry = @line2.Reduce(0);
SELECT @line2.STEquals(@reduced4) AS ShouldBeEqual;
go

DECLARE @line4 geometry = geometry::STGeomFromText('LINESTRING(0 0, 1 1, 2 0, 3 1)', 0);
DECLARE @reduced6 geometry = @line4.Reduce(10);
SELECT @reduced6.STIsValid() AS IsValid, @reduced6.STIsEmpty() AS IsEmpty;
go

DECLARE @gline1 geography = geography::STGeomFromText('LINESTRING(-122 47, -121 47.1, -120 47, -119 47.1)', 4326);
DECLARE @greduced1 geography = @gline1.Reduce(1000);
SELECT @greduced1.STIsValid() AS IsValid, @greduced1.STIsEmpty() AS IsEmpty;
go

DECLARE @gpoly1 geography = geography::STGeomFromText('POLYGON((-122 47, -122 48, -121 48, -121 47, -122 47))', 4326);
DECLARE @greduced2 geography = @gpoly1.Reduce(5000);
SELECT @greduced2.STIsValid() AS IsValid, @greduced2.STIsEmpty() AS IsEmpty;
go

DECLARE @gpoint1 geography = geography::STGeomFromText('POINT(-121 47)', 4326);
DECLARE @greduced4 geography = @gpoint1.Reduce(1000);
SELECT @gpoint1.STEquals(@greduced4) AS ShouldBeEqual;
go

DECLARE @gline2 geography = geography::STGeomFromText('LINESTRING(-122 47, -121 47.1, -120 47)', 4326);
DECLARE @greduced5 geography = @gline2.Reduce(0);
SELECT @greduced5.STIsValid() AS IsValid, @greduced5.STIsEmpty() AS IsEmpty;

DECLARE @gline3 geography = geography::STGeomFromText('LINESTRING(-122 47, -121 47.1, -120 47)', 4326);
DECLARE @greduced6 geography = @gline3.Reduce(100000);
SELECT @greduced6.STIsValid() AS IsValid, @greduced6.STIsEmpty() AS IsEmpty;
go

DECLARE @nullgeom geometry = NULL;
DECLARE @result1 geometry = @nullgeom.Reduce(1.0);
SELECT @result1 AS ShouldBeNull;
go

DECLARE @nullgeog geography = NULL;
DECLARE @result2 geography = @nullgeog.Reduce(1000);
SELECT @result2 AS ShouldBeNull;
go

DECLARE @empty1 geometry = geometry::STGeomFromText('LINESTRING EMPTY', 0);
DECLARE @result5 geometry = @empty1.Reduce(1.0);
SELECT @result5.STIsEmpty() AS ShouldBeEmpty;
go

DECLARE @g1 geometry = geometry::STGeomFromText('LINESTRING(0 0, 1 1, 2 0, 3 1)', 0).Reduce(0.5);
SELECT @g1.STIsValid(), @g1.STIsEmpty();
go

DECLARE @g2 geometry = geometry::STGeomFromText('LINESTRING(0 0, 0.1 0.1, 0.2 0, 0.3 0.1, 1 0)', 0).Reduce(0.05);
SELECT @g2.STIsValid(), @g2.STIsEmpty();
go

DECLARE @g3 geometry = geometry::STGeomFromText('POLYGON((0 0, 0 1, 0.5 1.1, 1 1, 1 0, 0 0))', 0).Reduce(0.2);
SELECT @g3.STIsValid(), @g3.STIsEmpty();
go

DECLARE @geo geography = geography::STGeomFromText('POLYGON((-122 47, -122 48, -121 48, -121 47, -122 47))', 4326);
SELECT @geo.STIsValid() AS BeforeValid;
go

DECLARE @geo geography = geography::STGeomFromText('POLYGON((-122 47, -122 48, -121 48, -121 47, -122 47))', 4326);
DECLARE @reduced geography = @geo.Reduce(5000);
SELECT @reduced.STIsValid() AS AfterValid, @reduced.STIsEmpty() AS AfterEmpty;
go

DECLARE @line geography = geography::STGeomFromText('LINESTRING(-122 47, -120 47)', 4326);
DECLARE @reduced geography = @line.Reduce(1000);
SELECT @reduced.STIsValid(), @reduced.STIsEmpty();
go

DECLARE @geo3 geography = geography::STGeomFromText('LINESTRING(-122 47, -120 47)', 4326).Reduce(1000);
DECLARE @endpoint geography = geography::STGeomFromText('POINT(-122 47)', 4326);
SELECT @geo3.STIntersects(@endpoint);
go

DECLARE @geo4 geography = geography::STGeomFromText('LINESTRING(-122 47, -121 47.1, -120 47)', 4326).Reduce(10);
SELECT @geo4.STIsValid(), @geo4.STIsEmpty();
go

DECLARE @geo5 geography = geography::STGeomFromText('LINESTRING(-122 47, -121 47.1, -120 47)', 4326).Reduce(0);
SELECT @geo5.STIsValid(), @geo5.STIsEmpty();
go

DECLARE @poly geography = geography::STGeomFromText('POLYGON((-122 47, -122 47.5, -122 48, -121.5 48, -121 48, -121 47.5, -121 47, -121.5 47, -122 47))', 4326).Reduce(5000);
SELECT @poly.STIsValid(), @poly.STIsEmpty();
go

DECLARE @zigzag geometry = geometry::STGeomFromText('LINESTRING(0 0, 0.1 0.1, 0.2 0, 0.3 0.1, 0.4 0, 0.5 0.1, 0.6 0, 0.7 0.1, 0.8 0, 0.9 0.1, 1 0)', 0);
DECLARE @reducedzigzag geometry = @zigzag.Reduce(0.05);
SELECT @reducedzigzag.STIsValid() AS IsValid, @reducedzigzag.STIsEmpty() AS IsEmpty;
go

DECLARE @complexpoly geometry = geometry::STGeomFromText('POLYGON((0 0, 0 0.1, 0 0.2, 0 0.3, 0 0.4, 0 0.5, 0 1, 1 1, 1 0.9, 1 0.8, 1 0.7, 1 0.6, 1 0.5, 1 0, 0 0))', 0);
DECLARE @reducedcomplexpoly geometry = @complexpoly.Reduce(0.15);
SELECT @reducedcomplexpoly.STIsValid() AS IsValid, @reducedcomplexpoly.STIsEmpty() AS IsEmpty;
go

DECLARE @gcomplex geography = geography::STGeomFromText('LINESTRING(-122 47, -121.9 47.01, -121.8 47.02, -121.7 47.01, -121.6 47.02, -121.5 47.01, -121.4 47.02, -121.3 47.01, -121.2 47.02, -121.1 47.01, -121 47)', 4326);
DECLARE @greducedcomplex geography = @gcomplex.Reduce(1000);
SELECT @greducedcomplex.STIsValid() AS IsValid, @greducedcomplex.STIsEmpty() AS IsEmpty;
go

DECLARE @testline geometry = geometry::STGeomFromText('LINESTRING(0 0, 1 1, 2 0, 3 1, 4 0)', 0);
DECLARE @r1 geometry = @testline.Reduce(0.1);
DECLARE @r2 geometry = @testline.Reduce(0.5);
DECLARE @r3 geometry = @testline.Reduce(1.0);
DECLARE @r4 geometry = @testline.Reduce(2.0);
SELECT 
    @r1.STIsValid() AS Valid_0_1,
    @r2.STIsValid() AS Valid_0_5,
    @r3.STIsValid() AS Valid_1_0,
    @r4.STIsValid() AS Valid_2_0;
go

DECLARE @gtestline geography = geography::STGeomFromText('LINESTRING(-122 47, -121 47.1, -120 47)', 4326);
DECLARE @gr1 geography = @gtestline.Reduce(100);
DECLARE @gr2 geography = @gtestline.Reduce(1000);
DECLARE @gr3 geography = @gtestline.Reduce(10000);
DECLARE @gr4 geography = @gtestline.Reduce(100000);
SELECT 
    @gr1.STIsValid() AS Valid_100m,
    @gr2.STIsValid() AS Valid_1km,
    @gr3.STIsValid() AS Valid_10km,
    @gr4.STIsValid() AS Valid_100km;
go

SELECT ID, LineColumn.Reduce(Tolerance).STIsValid() AS IsValid
FROM TestGeospatialMethods_REDUCE_GEOM1temp;
GO

SELECT ID 
FROM TestGeospatialMethods_REDUCE_GEOM1temp 
WHERE LineColumn.Reduce(Tolerance).STIsValid() = 1;
GO

SELECT ID, LineColumn.Reduce(ToleranceMeters).STIsValid() AS IsValid
FROM TestGeospatialMethods_REDUCE_GEOG1temp;
GO

SELECT ID 
FROM TestGeospatialMethods_REDUCE_GEOG1temp 
WHERE LineColumn.Reduce(ToleranceMeters).STIsValid() = 1;
GO

SELECT ID, LineColumn.Reduce(0.5).STIsValid() AS IsValid
FROM TestGeospatialMethods_REDUCE_GEOMtemp;
GO

SELECT ID, LineColumn.Reduce(Tolerance).STIsValid() AS IsValid
FROM TestGeospatialMethods_REDUCE_GEOMtemp;
GO

SELECT ID 
FROM TestGeospatialMethods_REDUCE_GEOMtemp 
WHERE LineColumn.Reduce(0.5).STIsValid() = 1;
GO

SELECT ID 
FROM TestGeospatialMethods_REDUCE_GEOMtemp 
WHERE LineColumn.Reduce(Tolerance).STIsValid() = 1;
GO

SELECT ID,
    CASE 
        WHEN LineColumn.Reduce(Tolerance).STIsValid() = 1 THEN 'Valid'
        ELSE 'Invalid'
    END AS Status
FROM TestGeospatialMethods_REDUCE_GEOMtemp;
GO

WITH ReducedGeoms AS (
    SELECT ID, LineColumn.Reduce(Tolerance) AS ReducedGeom
    FROM TestGeospatialMethods_REDUCE_GEOMtemp
)
SELECT ID, ReducedGeom.STIsValid() AS IsValid
FROM ReducedGeoms;
GO

SELECT ID, 
    (SELECT LineColumn.Reduce(0.5).STIsValid()) AS IsValid
FROM TestGeospatialMethods_REDUCE_GEOMtemp;
GO

SELECT ID, LineColumn.Reduce(Tolerance).STIsValid() AS IsValid
FROM TestGeospatialMethods_REDUCE_GEOMtemp
ORDER BY ID;
GO

SELECT Category, COUNT(*) AS Count
FROM TestGeospatialMethods_REDUCE_GEOMtemp
WHERE LineColumn.Reduce(0.5).STIsValid() = 1
GROUP BY Category;
GO

SELECT * FROM TestGeospatialMethods_REDUCE_ValidFromGeomTemp;
GO

SELECT ID, LineColumn.Reduce(1000).STIsValid() AS IsValid
FROM TestGeospatialMethods_REDUCE_GEOGtemp;
GO

SELECT ID, LineColumn.Reduce(ToleranceMeters).STIsValid() AS IsValid
FROM TestGeospatialMethods_REDUCE_GEOGtemp;
GO

SELECT ID 
FROM TestGeospatialMethods_REDUCE_GEOGtemp 
WHERE LineColumn.Reduce(1000).STIsValid() = 1;
GO

SELECT ID 
FROM TestGeospatialMethods_REDUCE_GEOGtemp 
WHERE LineColumn.Reduce(ToleranceMeters).STIsValid() = 1;
GO

DECLARE @toleranceMeters FLOAT = 5000;
SELECT ID 
FROM TestGeospatialMethods_REDUCE_GEOGtemp 
WHERE LineColumn.Reduce(@toleranceMeters).STIsValid() = 1;
GO

SELECT ID,
    CASE 
        WHEN LineColumn.Reduce(ToleranceMeters).STIsValid() = 1 THEN 'Valid'
        ELSE 'Invalid'
    END AS Status
FROM TestGeospatialMethods_REDUCE_GEOGtemp;
GO

WITH ReducedGeogs AS (
    SELECT ID, LineColumn.Reduce(ToleranceMeters) AS ReducedGeog
    FROM TestGeospatialMethods_REDUCE_GEOGtemp
)
SELECT ID, ReducedGeog.STIsValid() AS IsValid
FROM ReducedGeogs;
GO

SELECT ID, 
    (SELECT LineColumn.Reduce(1000).STIsValid()) AS IsValid
FROM TestGeospatialMethods_REDUCE_GEOGtemp;
GO

SELECT ID, LineColumn.Reduce(ToleranceMeters).STIsValid() AS IsValid
FROM TestGeospatialMethods_REDUCE_GEOGtemp
ORDER BY ID;
GO

SELECT Category, COUNT(*) AS Count
FROM TestGeospatialMethods_REDUCE_GEOGtemp
WHERE LineColumn.Reduce(ToleranceMeters).STIsValid() = 1
GROUP BY Category;
GO

SELECT * FROM TestGeospatialMethods_REDUCE_ValidFromGeogTemp;
GO

DECLARE @complex geometry = geometry::STGeomFromText('LINESTRING(0 0, 0.01 0.01, 0.02 0, 0.03 0.01, 1 0)', 0);
DECLARE @lowTol geometry = @complex.Reduce(0.001);
DECLARE @highTol geometry = @complex.Reduce(0.1);
SELECT 
    @complex.STEquals(@lowTol) AS LowTolerancePreserved,
    @complex.STEquals(@highTol) AS HighTolerancePreserved,
    @lowTol.STEquals(@highTol) AS BothEqual;
go

DECLARE @poly geometry = geometry::STGeomFromText('POLYGON((0 0, 0 0.01, 0 0.02, 0 1, 1 1, 1 0, 0 0))', 0);
DECLARE @reduced geometry = @poly.Reduce(0.05);
DECLARE @origArea FLOAT = @poly.STArea();
DECLARE @redArea FLOAT = @reduced.STArea();
SELECT 
    @origArea AS OriginalArea,
    @redArea AS ReducedArea,
    CASE WHEN @redArea <= @origArea THEN 1 ELSE 0 END AS AreaNotIncreased;
go

DECLARE @line geometry = geometry::STGeomFromText('LINESTRING(0 0, 1 1)', 0);
SELECT @line.Reduce(-1).STIsValid() AS NegativeToleranceValid;
go

DECLARE @nullGeom geometry = NULL;
SELECT @nullGeom.Reduce(0.5) AS NullGeometryResult;
go

DECLARE @invalid geometry = geometry::STGeomFromText('POLYGON((0 0, 1 1, 0 0))', 0);
SELECT @invalid.Reduce(0.5).STIsValid() AS InvalidGeometryReduced;
go

DECLARE @polyhole geometry = geometry::STGeomFromText('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0), (2 2, 2 8, 8 8, 8 2, 2 2))', 0);
SELECT @polyhole.Reduce(1.0).STIsValid() AS PolygonWithHoleValid;
go

DECLARE @original geometry = geometry::STGeomFromText('LINESTRING(0 0, 0.1 0, 0.2 0, 0.3 0, 1 0)', 0);
DECLARE @reduced geometry = @original.Reduce(0.15);
SELECT 
    @original.STAsText() AS OriginalWKT,
    @reduced.STAsText() AS ReducedWKT,
    LEN(@original.STAsText()) AS OriginalLength,
    LEN(@reduced.STAsText()) AS ReducedLength,
    CASE WHEN LEN(@reduced.STAsText()) <= LEN(@original.STAsText()) THEN 1 ELSE 0 END AS LikelyReduced;
go

DECLARE @precise geometry = geometry::STGeomFromText('LINESTRING(0 0, 0.001 0.001, 0.002 0, 1 0)', 0);
DECLARE @reducedPrecise geometry = @precise.Reduce(0.0005);
SELECT 
    @precise.STDistance(@reducedPrecise) AS DistanceDifference,
    CASE WHEN @precise.STDistance(@reducedPrecise) <= 0.0005 THEN 1 ELSE 0 END AS WithinTolerance;
go

DECLARE @large geometry = geometry::STGeomFromText('LINESTRING(0 0, 100 100, 200 0, 300 100, 400 0)', 0);
SELECT @large.Reduce(50).STIsValid() AS LargeGeometryValid;
go

DECLARE @unicode geometry = geometry::STGeomFromText(N'LINESTRING(0 0, 1 1, 2 0)', 0);
DECLARE @unicodereduced geometry = @unicode.Reduce(0.5);
SELECT @unicodereduced.STIsValid() AS IsValid;
GO

DECLARE @geom1 geometry = geometry::STGeomFromText('LINESTRING(0 0, 1 1, 2 0)', 4326);
DECLARE @reduced1 geometry = @geom1.Reduce(0.5);
SELECT @reduced1.STSrid AS SRID, @reduced1.STIsValid() AS IsValid;
GO

DECLARE @geom2 geometry = geometry::STGeomFromText('LINESTRING(0 0, 1 1, 2 0)', 3857);
DECLARE @reduced2 geometry = @geom2.Reduce(0.5);
SELECT @reduced2.STSrid AS SRID, @reduced2.STIsValid() AS IsValid;
GO

DECLARE @line3d geometry = geometry::STGeomFromText('LINESTRING(0 0 0, 1 1 1, 2 0 2, 3 1 3)', 0);
DECLARE @reduced3d geometry = @line3d.Reduce(0.5);
SELECT @reduced3d.STIsValid() AS IsValid, @reduced3d.STAsText() AS WKT;
GO

DECLARE @lineM geometry = geometry::STGeomFromText('LINESTRING(0 0 NULL 0, 1 1 NULL 1, 2 0 NULL 2)', 0);
DECLARE @reducedM geometry = @lineM.Reduce(0.5);
SELECT @reducedM.STIsValid() AS IsValid;
GO

DECLARE @largeLine geometry = geometry::STGeomFromText('LINESTRING(1000000 1000000, 1000001 1000001, 1000002 1000000)', 0);
SELECT @largeLine.Reduce(0.5).STIsValid() AS IsValid;
GO

DECLARE @smallLine geometry = geometry::STGeomFromText('LINESTRING(0.000001 0.000001, 0.000002 0.000002, 0.000003 0.000001)', 0);
SELECT @smallLine.Reduce(0.0000001).STIsValid() AS IsValid;
GO

DECLARE @gc geometry = geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0), LINESTRING(1 1, 2 2))', 0);
SELECT @gc.Reduce(0.5).STIsValid() AS IsValid;
GO

DECLARE @ccw geometry = geometry::STGeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))', 0);
SELECT @ccw.Reduce(0.1).STIsValid() AS IsValid;
GO

DECLARE @cw geometry = geometry::STGeomFromText('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))', 0);
SELECT @cw.Reduce(0.1).STIsValid() AS IsValid;
GO

DECLARE @cw geometry = geometry::STGeomFromText('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))', 0);
SELECT @cw.Reduce(0.1).STIsValid() AS IsValid;
GO

DECLARE @line1 geometry = geometry::STGeomFromText('LINESTRING(0 0, 1 1, 2 0)', 0);
SELECT @line1.Reduce(1).STIsValid() AS IntTolerance;
GO

DECLARE @geog4269 geography = geography::STGeomFromText('LINESTRING(-122 47, -121 47.1, -120 47)', 4269);
SELECT @geog4269.Reduce(1000).STIsValid() AS IsValid;
GO

DECLARE @crossDateline geography = geography::STGeomFromText('LINESTRING(179 0, -179 0)', 4326);
SELECT @crossDateline.Reduce(1000).STIsValid() AS IsValid;
GO

DECLARE @polar geography = geography::STGeomFromText('LINESTRING(0 89, 90 89, 180 89)', 4326);
SELECT @polar.Reduce(1000).STIsValid() AS IsValid;
GO

DECLARE @equator geography = geography::STGeomFromText('LINESTRING(0 0, 0.002 0.005, 0 0.01, 0.002 0.015, 0 0.02)', 4326);
DECLARE @lat60 geography = geography::STGeomFromText('LINESTRING(0 60, 0.002 60.005, 0 60.01, 0.002 60.015, 0 60.02)', 4326);

SELECT '100m tolerance' as Test,'Equator' as Location, LEN(@equator.Reduce(100).STAsBinary()) as Reduced_Len;
SELECT '100m tolerance' as Test,'60° Lat' as Location, LEN(@lat60.Reduce(100).STAsBinary()) as Reduced_Len;
SELECT '150m tolerance' as Test, 'Equator' as Location, LEN(@equator.Reduce(150).STAsBinary()) as Reduced_Len;
SELECT '150m tolerance' as Test, '60° Lat' as Location, LEN(@lat60.Reduce(150).STAsBinary()) as Reduced_Len;
SELECT '200m tolerance' as Test, 'Equator' as Location, LEN(@equator.Reduce(200).STAsBinary()) as Reduced_Len;
SELECT '200m tolerance' as Test, '60° Lat' as Location, LEN(@lat60.Reduce(200).STAsBinary()) as Reduced_Len;
SELECT '250m tolerance' as Test, 'Equator' as Location, LEN(@equator.Reduce(250).STAsBinary()) as Reduced_Len;
SELECT '250m tolerance' as Test, '60° Lat' as Location, LEN(@lat60.Reduce(250).STAsBinary()) as Reduced_Len;
go