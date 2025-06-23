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