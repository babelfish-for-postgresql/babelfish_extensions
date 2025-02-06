DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SELECT @point1.STEquals(@point2) AS Equal;
go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point1.STEquals(@point2) AS Equal;
go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point1.STContains(@point2) AS isIN;
go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 0);
SELECT @point1.STEquals(@point2) AS Equal;
go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point1 . STEquals(@point2) AS Equal;
go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point1 . STContains(@point2) AS isIN;
go

DECLARE @point1 geography;
SET @point1 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point1.STSrid;
Go

-- Verifying with precision
DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SELECT STEquals(@point1, @point2);
go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STGeomFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SELECT @point1.STEquals(@point2) AS Equal;
go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684000 47.658678768678100)', 4326);
SELECT STEquals(@point1, @point2);
go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SELECT @point1 . STEquals ( @point2 );
go

SELECT PointColumn1.STEquals(PointColumn2) AS Equals FROM TestSpatialFunction_YourTableTemp2 ORDER BY PointColumn1.STX;
go

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
SELECT PointColumn1.STEquals(@point1) AS Equals FROM TestSpatialFunction_YourTableTemp2 ORDER BY PointColumn1.STX;
go

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
SELECT @point1.STEquals(PointColumn2) AS Equals FROM TestSpatialFunction_YourTableTemp2 ORDER BY PointColumn1.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @isEqual BIT = 0;
SELECT PointColumn.STSrid FROM TestSpatialFunction_YourTableTemp WHERE PointColumn.STEquals(@referencePoint) = @isEqual ORDER BY PointColumn.STSrid;
go

SELECT ID, PointColumn1.STEquals(PointColumn2) AS Equal_points FROM TestSpatialFunction_YourTableTemp2 ORDER BY PointColumn1.STX;
go

SELECT PointA.STAsText(),PointB.STAsText() FROM TestSpatialFunction_TableATemp JOIN TestSpatialFunction_TableBTemp ON PointA.STEquals(TestSpatialFunction_TableBTemp.PointB) != 1 ORDER BY PointA.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointA.STAsText(),PointB.STAsText() FROM TestSpatialFunction_TableATemp JOIN TestSpatialFunction_TableBTemp ON @referencePoint.STEquals(TestSpatialFunction_TableBTemp.PointB) = 1 ORDER BY PointA.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointA.STAsText(),PointB.STAsText() FROM TestSpatialFunction_TableATemp JOIN TestSpatialFunction_TableBTemp ON PointA.STEquals(@referencePoint) != 1 ORDER BY PointA.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STSrid FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STSrid;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STSrid FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STSrid;
go

SELECT PointColumn1.STAsText() FROM TestSpatialFunction_YourTableTemp2 ORDER BY PointColumn1.STX;
go

DECLARE @isEqual BIT = 1;
SELECT ID, PointColumn1.STEquals(PointColumn2) AS isEqual,
CASE WHEN PointColumn1.STEquals(PointColumn2) = @isEqual THEN 'yes' ELSE 'no'
END AS isEqual
FROM TestSpatialFunction_YourTableTemp2 ORDER BY PointColumn1.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH EqualCTE AS ( SELECT ID, PointColumn.STEquals(@referencePoint) AS Equality FROM TestSpatialFunction_YourTableTemp)
SELECT * FROM EqualCTE WHERE Equality = 1 ORDER BY Equality;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH EqualCTE AS ( SELECT ID, PointColumn.STEquals(@referencePoint) AS Equal FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX)
SELECT * FROM EqualCTE WHERE Equal = 1.0 ORDER BY Equal;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH EqualCTE AS ( SELECT ID, @referencePoint.STEquals(PointColumn) AS Equal FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX)
SELECT * FROM EqualCTE WHERE Equal != 1.0 ORDER BY Equal;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @isEqual BIT = 1;
SELECT ID, PointColumn.STEquals(@referencePoint) AS EqualityReferencePoint,
CASE WHEN PointColumn.STEquals(@referencePoint) = @isEqual THEN 'Close'
ELSE 'Far'
END AS Proximity
FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, @referencePoint.STEquals(PointColumn) AS EqualityReferencePoint,
CASE WHEN @referencePoint.STEquals(PointColumn) = @referencePoint.STY THEN 'Close'
ELSE 'Far'
END AS Proximity
FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
go

DECLARE @Ranges TABLE (MinDistance float, MaxDistance float);
INSERT INTO @Ranges VALUES (0, 5), (5, 10), (10, 15);
SELECT * FROM ( SELECT ID,
CASE WHEN PointColumn1.STEquals(PointColumn2) BETWEEN 0 AND 1 THEN 'yes'
ELSE 'no'
END AS Range
FROM TestSpatialFunction_YourTableTemp2 ORDER BY PointColumn1.STX
) AS Source
PIVOT ( COUNT(ID) FOR Range IN ([0-5], [5.1-10], [10.1-15], [15.1+])) AS PivotTable;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STEquals(@referencePoint) AS Equality FROM TestSpatialFunction_DB.dbo.TestSpatialFunction_YourTable1Temp ORDER BY PointColumn.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STEquals(@referencePoint) AS Equal,
JSON_QUERY('{"Equal":' + CAST(PointColumn.STEquals(@referencePoint) AS NVARCHAR(MAX)) + '}') AS Json
FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, @referencePoint.STEquals(PointColumn) AS Equal,
JSON_QUERY('{"Equal":' + CAST(@referencePoint.STEquals(PointColumn) AS NVARCHAR(MAX)) + '}') Json
FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
go

SELECT [PointColumn1].STEquals([PointColumn2]) AS Equality FROM [TestSpatialFunction_YourTableTemp2] ORDER BY PointColumn1.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @isEqual BIT = 1;
DECLARE @sql NVARCHAR(MAX);
DECLARE @params NVARCHAR(MAX);
SET @sql = N'
SELECT ID, PointColumn.STEquals(@referencePoint) AS EqualityReferencePoint,
CASE WHEN PointColumn.STEquals(@referencePoint) = @isEqual THEN ''Close''
ELSE ''Far''
END AS Proximity
FROM TestSpatialFunction_YourTableTemp
WHERE PointColumn.STEquals(@referencePoint) = @isEqual;';
SET @params = N'@referencePoint geometry, @isEqual float';
EXEC sp_executesql @sql, @params, @referencePoint, @isEqual;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STEquals(@referencePoint) AS Equality FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
SELECT TestSpatialFunction_YourTableTemp.PointColumn.STEquals(@referencePoint) AS Equality FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
SELECT dbo.TestSpatialFunction_YourTableTemp.PointColumn.STEquals(@referencePoint) AS Equality FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
go

DECLARE @pnt geometry;
SET @pnt = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
select geometry::Point(@pnt.STY, @pnt.STX, 4326).STEquals(@pnt)
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @equal BIT = 1;
SELECT ROUND(PointColumn.STEquals(@referencePoint) / @equal, 0) * @equal AS Equalitygroup,
COUNT(*) AS PointCount
FROM TestSpatialFunction_YourTableTemp
GROUP BY ROUND(PointColumn.STEquals(@referencePoint) / @equal, 0) * @equal
ORDER BY Equalitygroup;
GO

DECLARE @referencePoint geometry = geometry::Point(1.0, 0.0, 4326);
SELECT ROUND(PointColumn.STEquals(@referencePoint) / @referencePoint.STX, 0) * @referencePoint.STX AS Equalitygroup,
COUNT(*) AS PointCount
FROM TestSpatialFunction_YourTableTemp
GROUP BY ROUND(PointColumn.STEquals(@referencePoint) / @referencePoint.STX, 0) * @referencePoint.STX
ORDER BY Equalitygroup;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn1.STEquals(PointColumn2) AS equal,
cast(PointColumn1.STEquals(@referencePoint) as int) - LAG(PointColumn1.STEquals(PointColumn2)) OVER (ORDER BY ID) AS Equalitygroup 
FROM TestSpatialFunction_YourTableTemp2 ORDER BY PointColumn1.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STEquals(@referencePoint) AS equal,
cast(@referencePoint.STContains(PointColumn) as int) - LAG(@referencePoint.STX) OVER (ORDER BY ID) AS Equalitygroup
FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
GO

-- Verifying with precision
DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SELECT STContains(@point1, @point2);
go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STGeomFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SELECT @point1.STContains(@point2) AS isIN;
go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684000 47.658678768678100)', 4326);
SELECT STContains(@point1, @point2);
go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SELECT @point1.STContains(@point2);
go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SELECT @point1 . STContains ( @point2 );
Go

SELECT ID, PointColumn1.STContains(PointColumn2) AS contain FROM TestSpatialFunction_YourTableTemp2 ORDER BY PointColumn1.STX;
GO

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
SELECT ID, PointColumn1.STContains(@point1) AS contain FROM TestSpatialFunction_YourTableTemp2 ORDER BY PointColumn1.STX;
GO

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
SELECT ID, @point1.STContains(PointColumn2) AS contain FROM TestSpatialFunction_YourTableTemp2 ORDER BY PointColumn1.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @contain BIT = 1;
SELECT PointColumn.STAsText() FROM TestSpatialFunction_YourTableTemp WHERE PointColumn.STContains(@referencePoint) = @contain ORDER BY PointColumn.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STAsText() FROM TestSpatialFunction_YourTableTemp WHERE @referencePoint.STContains(PointColumn) = @referencePoint.STX ORDER BY PointColumn.STX;
GO

SELECT ID, PointColumn1.STContains(PointColumn2) AS contain FROM TestSpatialFunction_YourTableTemp2 ORDER BY PointColumn1.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STAsText() FROM TestSpatialFunction_YourTableTemp WHERE PointColumn.STContains(@referencePoint) != @referencePoint.STX ORDER BY PointColumn.STX;
GO

SELECT PointA.STAsText(),PointB.STAsText() FROM TestSpatialFunction_TableATemp JOIN TestSpatialFunction_TableBTemp ON PointA.STContains(TestSpatialFunction_TableBTemp.PointB) = 1 ORDER BY TestSpatialFunction_TableBTemp.PointB.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointA.STAsText(),PointB.STAsText() FROM TestSpatialFunction_TableATemp JOIN TestSpatialFunction_TableBTemp ON @referencePoint.STContains(TestSpatialFunction_TableBTemp.PointB) = 1 ORDER BY TestSpatialFunction_TableBTemp.PointB.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointA.STAsText(),PointB.STAsText() FROM TestSpatialFunction_TableATemp JOIN TestSpatialFunction_TableBTemp ON PointA.STContains(@referencePoint) = 1 ORDER BY TestSpatialFunction_TableBTemp.PointB.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointA.STAsText(),PointB.STAsText() FROM TestSpatialFunction_TableATemp JOIN TestSpatialFunction_TableBTemp ON TestSpatialFunction_TableBTemp.PointB.STContains(@referencePoint) = 0 ORDER BY TestSpatialFunction_TableBTemp.PointB.STX;
GO

SELECT PointColumn1.STAsText() FROM TestSpatialFunction_YourTableTemp2 ORDER BY PointColumn1.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STAsText() FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STAsText() FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
GO

DECLARE @contains BIT = 1 ;
SELECT ID, PointColumn1.STContains(PointColumn2) AS doContain,
CASE WHEN PointColumn1.STContains(PointColumn2) = @contains THEN 'Contains' ELSE 'Do_not_contain'
END AS Proximity
FROM TestSpatialFunction_YourTableTemp2 ORDER BY PointColumn1.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn1.STContains(@referencePoint) AS contain,
CASE WHEN @referencePoint.STContains(PointColumn2) = @referencePoint.STX THEN 'Contains' ELSE 'Do_not_contain'
END AS Proximity
FROM TestSpatialFunction_YourTableTemp2 ORDER BY PointColumn1.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH CTE AS ( SELECT ID, PointColumn.STContains(@referencePoint) AS contain FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX)
SELECT * FROM CTE WHERE contain = 1 ORDER BY contain;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH CTE AS ( SELECT ID, @referencePoint.STContains(PointColumn) AS contain FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX)
SELECT * FROM CTE WHERE contain = 1 ORDER BY contain;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @contains BIT = 1;
SELECT ID, PointColumn.STContains(@referencePoint) AS ReferencePoint,
CASE WHEN PointColumn.STContains(@referencePoint) = @contains THEN 'contain'
ELSE 'do_not_contain'
END AS Proximity
FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, @referencePoint.STContains(PointColumn) AS ReferencePoint,
CASE WHEN @referencePoint.STContains(PointColumn) = @referencePoint.STY THEN 'contain'
ELSE 'do_not_contain'
END AS Proximity
FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
go

DECLARE @Ranges TABLE (MinDistance float, MaxDistance float);
INSERT INTO @Ranges VALUES (0, 5), (5, 10), (10, 15);
SELECT * FROM ( SELECT ID,
CASE WHEN PointColumn1.STContains(PointColumn2) BETWEEN 0 AND 1 THEN 'contain'
ELSE 'do_not_contain'
END AS Range
FROM TestSpatialFunction_YourTableTemp2 ORDER BY PointColumn1.STX
) AS Source
PIVOT ( COUNT(ID) FOR Range IN ([0-5], [5.1-10], [10.1-15], [15.1+])) AS PivotTable;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STContains(@referencePoint) AS contain FROM TestSpatialFunction_DB.dbo.TestSpatialFunction_YourTable1Temp ORDER BY PointColumn.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STContains(@referencePoint) AS contain,
JSON_QUERY('{"Contain":' + CAST(PointColumn.STContains(@referencePoint) AS NVARCHAR(MAX)) + '}') AS Json
FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, @referencePoint.STContains(PointColumn) AS contain,
JSON_QUERY('{"Contain":' + CAST(@referencePoint.STContains(PointColumn) AS NVARCHAR(MAX)) + '}') Json
FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
go

SELECT [PointColumn1].STContains([PointColumn2]) AS contain FROM [TestSpatialFunction_YourTableTemp2] ORDER BY PointColumn1.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @contains BIT = 1;
DECLARE @sql NVARCHAR(MAX);
DECLARE @params NVARCHAR(MAX);
SET @sql = N'
SELECT ID, PointColumn.STContains(@referencePoint) AS EqualityReferencePoint,
CASE WHEN PointColumn.STContains(@referencePoint) = @contains THEN ''contains''
ELSE ''do_not_contain''
END AS Proximity
FROM TestSpatialFunction_YourTableTemp
WHERE PointColumn.STContains(@referencePoint) = @contains;';
SET @params = N'@referencePoint geometry, @contains float';
EXEC sp_executesql @sql, @params, @referencePoint, @contains;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STContains(@referencePoint) AS contain FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
SELECT TestSpatialFunction_YourTableTemp.PointColumn.STContains(@referencePoint) AS contain FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
SELECT dbo.TestSpatialFunction_YourTableTemp.PointColumn.STContains(@referencePoint) AS contain FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
go

DECLARE @pnt geometry;
SET @pnt = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
select geometry::Point(@pnt.STY, @pnt.STX, 4326).STContains(@pnt)

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @contains BIT = 1;
SELECT ROUND(PointColumn.STContains(@referencePoint) / @contains, 0) * @contains AS Grp,
COUNT(*) AS PointCount
FROM TestSpatialFunction_YourTableTemp
GROUP BY ROUND(PointColumn.STContains(@referencePoint) / @contains, 0) * @contains
ORDER BY Grp;
GO

DECLARE @referencePoint geometry = geometry::Point(1.0, 0.0, 4326);
SELECT ROUND(PointColumn.STContains(@referencePoint) / @referencePoint.STX, 0) * @referencePoint.STX AS GRP,
COUNT(*) AS PointCount
FROM TestSpatialFunction_YourTableTemp
GROUP BY ROUND(PointColumn.STContains(@referencePoint) / @referencePoint.STX, 0) * @referencePoint.STX
ORDER BY Grp;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn1.STContains(PointColumn2) AS contain,
cast(PointColumn1.STContains(@referencePoint) as int) - LAG(PointColumn1.STContains(PointColumn2)) OVER (ORDER BY ID) AS Difference 
FROM TestSpatialFunction_YourTableTemp2 ORDER BY PointColumn1.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STContains(@referencePoint) AS contain,
cast(@referencePoint.STContains(PointColumn) as int) - LAG(@referencePoint.STX) OVER (ORDER BY ID) AS Difference
FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
GO

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STArea(@point);
go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STArea(@point);
go

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point.STArea();
Go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point.STArea();
Go

DECLARE @point geometry;
SET @point = geometry::POINT(22.34900, -47.65100, 4326);
SELECT @point . STArea ( );
Go

DECLARE @point geography;
SET @point = geography::POINT(22.34900, -47.65100, 4326);
SELECT @point . STArea ( );
Go

SELECT location.STArea() from TestSpatialFunction_SPATIALPOINTGEOM_dttemp ORDER BY location.STX;
GO

SELECT location.STArea() from TestSpatialFunction_SPATIALPOINTGEOG_dttemp ORDER BY location.Lat;
GO

DECLARE @point geography;
SET @point = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STArea(@point);
SELECT @point.STArea();
Go

DECLARE @point geography;
SET @point = geography::Point(22.34900, -47.65100, 4326);
SELECT STArea(@point);
SELECT @point.STArea();
Go

DECLARE @point1 geometry, @point2 geometry, @point3 geometry;
SET @point1 = geometry::STPointFromText(null, 4326);
SET @point2 = geometry::STGeomFromText(null, 4326);
SET @point3 = geometry::Point(22.34900, -47.65100, 4326);
SELECT @point1.STEquals(@point2);
SELECT @point3.STEquals(@point2);
SELECT @point1.STEquals(@point3);
SELECT @point1.STContains(@point2);
SELECT @point3.STContains(@point2);
SELECT @point1.STContains(@point3);
go

-- Negative test for Geospatial functions
DECLARE @point1 geometry, @point2 varchar(50), @point3 int;
SET @point1 = geometry::Point(22.34900, -47.65100, 4326);
SET @point2 = 'Test_String';
SELECT @point1.STEquals(@point2);
SELECT @point1.STContains(@point2);
go

DECLARE @point1 geography, @point2 varchar(50), @point3 int;
SET @point1 = geography::Point(22.34900, -47.65100, 4326);
SET @point2 = 'Test_String';
SELECT @point1.STEquals(@point2);
SELECT @point1.STContains(@point2);
go

-- Null test for Geospatial functions
DECLARE @point1 geography, @point2 geography, @point3 geography;
SET @point1 = geography::STPointFromText(null, 4326);
SET @point2 = geography::STGeomFromText(null, 4326);
SET @point3 = geography::Point(22.34900, -47.65100, 4326);
SELECT @point1.STEquals(@point2);
SELECT @point3.STEquals(@point2);
SELECT @point1.STEquals(@point3);
SELECT @point1.STContains(@point2);
SELECT @point3.STContains(@point2);
SELECT @point1.STContains(@point3);
go

DECLARE @g geometry; 
SELECT @g.STArea(); 
go

SELECT location.STArea() from TestSpatialFunction_SPATIALPOINTGEOG_dttemp ORDER BY location.Lat;
GO

-- Combining geometry and geography in a single query
DECLARE @point1 geometry, @point2 geography;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point1.STContains(@point2);
go

DECLARE @point1 geometry, @point2 geography;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point2.STContains(@point1);
go

DECLARE @point1 geometry, @point2 geography;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point1.STEquals(@point2);
go

DECLARE @point1 geometry, @point2 geography;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point2.STEquals(@point1);
go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::Point(22.34900, -47.65100, 4326);
SET @point2 = geometry::STGeomFromText('POINT(1 1)', 0);
SELECT @point1.STEquals(@point2);
go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::Point(22.34900, -47.65100, 4326);
SET @point2 = geometry::STGeomFromText('POINT(1 1)', 0);
SELECT @point1.STContains(@point2);
go

DECLARE @point1 geometry;
SET @point1 = geometry::Point(3.0, 4.0, 4326);
SELECT PointColumn.STAsText() from TestSpatialFunction_YourTableTemp where PointColumn <> @point1;
GO

DECLARE @point1 geometry;
SET @point1 = geometry::Point(3.0, 4.0, 4326);
SELECT PointColumn.STAsText() from TestSpatialFunction_YourTableTemp where PointColumn = @point1;
GO

SELECT PointColumn.STSrid from TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STSrid;
GO

SELECT [PointColumn].[STSrid] from TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STX;
GO

SELECT location.STSrid from TestSpatialFunction_SPATIALPOINTGEOG_dttemp ORDER BY location.STSrid;
GO

SELECT [location].[STSrid] from TestSpatialFunction_SPATIALPOINTGEOG_dttemp ORDER BY location.Lat;
GO

DECLARE @point geometry; 
SET @point = geometry::Point(1.0, 2.0, 4326); 
SELECT @point.STSrid AS Srid;
GO

DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT PointColumn.STSrid FROM TestSpatialFunction_YourTableTemp WHERE PointColumn.STSrid = @point.STSrid ORDER BY PointColumn.STSrid;
GO

DECLARE @point geography = geography::Point(1.0, 2.0, 4326);
SELECT location.STSrid FROM TestSpatialFunction_SPATIALPOINTGEOG_dttemp WHERE location.STSrid = @point.STSrid ORDER BY location.STSrid;
GO

SELECT * FROM TestSpatialFunction_TableATemp JOIN TestSpatialFunction_TableBTemp ON TestSpatialFunction_TableATemp.PointA.STSrid = TestSpatialFunction_TableBTemp.PointB.STSrid ORDER BY TestSpatialFunction_TableBTemp.PointB.STSrid;
GO

DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT * FROM TestSpatialFunction_TableATemp JOIN TestSpatialFunction_TableBTemp ON TestSpatialFunction_TableATemp.PointA.STSrid = @point.STSrid ORDER BY TestSpatialFunction_TableBTemp.PointB.STSrid;
GO

SELECT PointColumn.STSrid FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STSrid;
GO

DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT PointColumn.STSrid FROM TestSpatialFunction_YourTableTemp ORDER BY @point.STSrid;
GO

SELECT PointColumn.STSrid AS SRID FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STSrid;
GO

SELECT TestSpatialFunction_YourTableTemp.PointColumn.STSrid AS SRID FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STSrid;
GO

SELECT dbo.YourTable.PointColumn.STSrid AS SRID FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STSrid;
GO

SELECT ID, PointColumn.STSrid AS SRID,
JSON_QUERY('{"SRID":' + CAST(PointColumn.STSrid AS NVARCHAR(MAX)) + '}') AS SRIDJson 
FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STSrid;
GO

SELECT TestSpatialFunction_YourTable1Temp.ID, TestSpatialFunction_YourTable1Temp.PointColumn.STSrid AS SRID 
FROM TestSpatialFunction_DB.dbo.TestSpatialFunction_YourTable1Temp;
GO

DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT PointColumn.STSrid AS SRID, COUNT(*) AS PointCount 
FROM TestSpatialFunction_YourTableTemp GROUP BY PointColumn.STSrid ORDER BY PointCount;
GO

SELECT ID, PointColumn.STSrid AS XCoordinate, 
CASE WHEN PointColumn.STSrid = 0 THEN 'Zero SRID'
ELSE 'Positive SRID' END AS SRID FROM TestSpatialFunction_YourTableTemp ORDER BY PointColumn.STSrid;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326); 
UPDATE TestSpatialFunction_YourTableTemp SET PointColumn = @referencePoint
WHERE PointColumn.STSrid = @referencePoint.STSrid;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326); 
UPDATE TestSpatialFunction_YourTableTemp SET PointColumn = @referencePoint
WHERE PointColumn.STEquals(@referencePoint) != 1;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326); 
UPDATE TestSpatialFunction_YourTableTemp SET PointColumn = @referencePoint
WHERE @referencePoint.STEquals(PointColumn) = 1;
go


--STIntersects

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
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point1 . STIntersects(@point2) AS Intersecting;
go

-- Verifying with precision
DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SELECT STIntersects(@point1, @point2);
go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STGeomFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SELECT @point1.STIntersects(@point2) AS Intersecting;
go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684000 47.658678768678100)', 4326);
SELECT STIntersects(@point1, @point2);
go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SELECT @point1 . STIntersects ( @point2 );
go

--Use in an ORDER BY Clause
SELECT PointColumn1.STIntersects(PointColumn2) AS Intersects FROM TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
SELECT PointColumn1.STIntersects(@point1) AS Intersects FROM TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
SELECT @point1.STIntersects(PointColumn2) AS Intersects FROM TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

SELECT ID, PointColumn1.STIntersects(PointColumn2) AS Intersecting_points FROM TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STIntersects(@referencePoint) AS Intersection FROM TestGeospatialMethods_DB.dbo.TestGeospatialMethods_YourTable1Temp ORDER BY PointColumn.STX;
go

--Use in a WHERE Clause
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @doesintersect BIT = 0;
SELECT PointColumn.STSrid FROM TestGeospatialMethods_YourTableTemp WHERE PointColumn.STIntersects(@referencePoint) = @doesintersect ORDER BY PointColumn.STSrid;
go

--Use in a CTE (Common Table Expression)
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH IntersectCTE AS ( SELECT ID, PointColumn.STIntersects(@referencePoint) AS Intersection FROM TestGeospatialMethods_YourTableTemp)
SELECT * FROM IntersectCTE WHERE Intersection = 1 ORDER BY Intersection;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH IntersectCTE AS ( SELECT ID, PointColumn.STIntersects(@referencePoint) AS Intersections FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX)
SELECT * FROM IntersectCTE WHERE Intersections = 1.0 ORDER BY Intersections;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH IntersectCTE AS ( SELECT ID, @referencePoint.STIntersects(PointColumn) AS Intersections FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX)
SELECT * FROM IntersectCTE WHERE Intersections != 1.0 ORDER BY Intersections;
GO

-- Use in a JOIN Operation
SELECT PointA.STAsText(),PointB.STAsText() FROM TestGeospatialMethods_TableATemp JOIN TestGeospatialMethods_TableBTemp ON PointA.STIntersects(TestGeospatialMethods_TableBTemp.PointB) != 1 ORDER BY PointA.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointA.STAsText(),PointB.STAsText() FROM TestGeospatialMethods_TableATemp JOIN TestGeospatialMethods_TableBTemp ON @referencePoint.STIntersects(TestGeospatialMethods_TableBTemp.PointB) = 1 ORDER BY PointA.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointA.STAsText(),PointB.STAsText() FROM TestGeospatialMethods_TableATemp JOIN TestGeospatialMethods_TableBTemp ON PointA.STIntersects(@referencePoint) != 1 ORDER BY PointA.STX;
go

--Use in a CASE Statement
DECLARE @doesintersect BIT = 1;
SELECT ID, PointColumn1.STIntersects(PointColumn2) AS doesintersect,
CASE WHEN PointColumn1.STIntersects(PointColumn2) = @doesintersect THEN 'yes' ELSE 'no'
END AS doesintersect
FROM TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

--Use in a Conditional Statement
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @doesintersect BIT = 1;
SELECT ID, PointColumn.STIntersects(@referencePoint) AS IntersectingReferancePoint,
CASE WHEN PointColumn.STIntersects(@referencePoint) = @doesintersect THEN 'Close'
ELSE 'Far'
END AS Proximity
FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, @referencePoint.STIntersects(PointColumn) AS IntersectingReferancePoint,
CASE WHEN @referencePoint.STIntersects(PointColumn) = @referencePoint.STY THEN 'Close'
ELSE 'Far'
END AS Proximity
FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

--Use in a Pivot Query
DECLARE @Ranges TABLE (MinDistance float, MaxDistance float);
INSERT INTO @Ranges VALUES (0, 5), (5, 10), (10, 15);
SELECT * FROM ( SELECT ID,
CASE WHEN PointColumn1.STIntersects(PointColumn2) BETWEEN 0 AND 1 THEN 'yes'
ELSE 'no'
END AS Range
FROM TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX
) AS Source
PIVOT ( COUNT(ID) FOR Range IN ([0-5], [5.1-10], [10.1-15], [15.1+])) AS PivotTable;
go

--Use in a JSON Output
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STIntersects(@referencePoint) AS Intersections,
JSON_QUERY('{"Intersections":' + CAST(PointColumn.STIntersects(@referencePoint) AS NVARCHAR(MAX)) + '}') AS Json
FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, @referencePoint.STIntersects(PointColumn) AS Intersections,
JSON_QUERY('{"Intersections":' + CAST(@referencePoint.STIntersects(PointColumn) AS NVARCHAR(MAX)) + '}') Json
FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

--Using Square brackets '[]' identifier
SELECT [PointColumn1].STIntersects([PointColumn2]) AS Intersection FROM TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

--Use in Prepared Statement
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @doesintersect BIT = 1;
DECLARE @sql NVARCHAR(MAX);
DECLARE @params NVARCHAR(MAX);
SET @sql = N'
SELECT ID, PointColumn.STIntersects(@referencePoint) AS IntersectingReferancePoint,
CASE WHEN PointColumn.STIntersects(@referencePoint) = @doesintersect THEN ''Close''
ELSE ''Far''
END AS Proximity
FROM TestGeospatialMethods_YourTableTemp
WHERE PointColumn.STIntersects(@referencePoint) = @doesintersect;';
SET @params = N'@referencePoint geometry, @doesintersect float';
EXEC sp_executesql @sql, @params, @referencePoint, @doesintersect;
go

--Use in Multi-Part column name Statements
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STIntersects(@referencePoint) AS Intersection FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
SELECT TestGeospatialMethods_YourTableTemp.PointColumn.STIntersects(@referencePoint) AS Intersection FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
SELECT TestGeospatialMethods_YourTableTemp.PointColumn.STIntersects(@referencePoint) AS Intersection FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

--Use in function.STIntersects(@point) Statements
DECLARE @pnt geometry;
SET @pnt = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
select geometry::Point(@pnt.STY, @pnt.STX, 4326).STIntersects(@pnt)
go

--Use in a Group By Clause
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @intersection_points BIT = 1;
SELECT ROUND(PointColumn.STIntersects(@referencePoint) / @intersection_points, 0) * @intersection_points AS Intersectinggroup,
COUNT(*) AS PointCount
FROM TestGeospatialMethods_YourTableTemp
GROUP BY ROUND(PointColumn.STIntersects(@referencePoint) / @intersection_points, 0) * @intersection_points
ORDER BY Intersectinggroup;
go

DECLARE @referencePoint geometry = geometry::Point(1.0, 0.0, 4326);
SELECT ROUND(PointColumn.STIntersects(@referencePoint) / @referencePoint.STX, 0) * @referencePoint.STX AS Intersectinggroup,
COUNT(*) AS PointCount
FROM TestGeospatialMethods_YourTableTemp
GROUP BY ROUND(PointColumn.STIntersects(@referencePoint) / @referencePoint.STX, 0) * @referencePoint.STX
ORDER BY Intersectinggroup;
go

-- Use in a Window Function
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn1.STIntersects(PointColumn2) AS intersection_points,
cast(PointColumn1.STIntersects(@referencePoint) as int) - LAG(PointColumn1.STIntersects(PointColumn2)) OVER (ORDER BY ID) AS Intersectinggroup 
FROM TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STIntersects(@referencePoint) AS intersection_points,
cast(@referencePoint.STDisjoint(PointColumn) as int) - LAG(@referencePoint.STX) OVER (ORDER BY ID) AS Intersectinggroup
FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

--Use in an UPDATE Statement
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326); 
UPDATE TestGeospatialMethods_YourTableTemp SET PointColumn = @referencePoint
WHERE @referencePoint.STIntersects(PointColumn) = 1;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326); 
UPDATE TestGeospatialMethods_YourTableTemp SET PointColumn = @referencePoint
WHERE PointColumn.STIntersects(@referencePoint) != 1;
go

--Cross-database query to retrieve intersects
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STIntersects(@referencePoint) AS Disjoint FROM TestGeospatialMethods_DB.dbo.TestGeospatialMethods_YourTable1Temp;
go

--STDisjoint

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point1.STDisjoint(@point2) AS disjoint;
go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
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
SET @point1 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geometry::STPointFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SELECT @point1 . STDisjoint ( @point2 );
go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STGeomFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.354657658684900 47.658678768678100)', 4326);
SELECT @point1.STDisjoint(@point2);
go

--Use in an ORDER BY Clause
SELECT ID, PointColumn1.STDisjoint(PointColumn2) AS disjoint FROM TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
SELECT ID, PointColumn1.STDisjoint(@point1) AS disjoint FROM TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
SELECT ID, @point1.STDisjoint(PointColumn2) AS disjoint FROM TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

--Use in a WHERE Clause
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @disjoint BIT = 1;
SELECT PointColumn.STAsText() FROM TestGeospatialMethods_YourTableTemp WHERE PointColumn.STDisjoint(@referencePoint) = @disjoint ORDER BY PointColumn.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STAsText() FROM TestGeospatialMethods_YourTableTemp WHERE @referencePoint.STDisjoint(PointColumn) = @referencePoint.STX ORDER BY PointColumn.STX;
go

SELECT ID, PointColumn1.STDisjoint(PointColumn2) AS disjoint FROM TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STAsText() FROM TestGeospatialMethods_YourTableTemp WHERE PointColumn.STDisjoint(@referencePoint) != @referencePoint.STX ORDER BY PointColumn.STX;
go

--Use in a JOIN Operation
SELECT PointA.STAsText(),PointB.STAsText() FROM TestGeospatialMethods_TableATemp JOIN TestGeospatialMethods_TableBTemp ON PointA.STDisjoint(TestGeospatialMethods_TableBTemp.PointB) = 1 ORDER BY TestGeospatialMethods_TableBTemp.PointB.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointA.STAsText(),PointB.STAsText() FROM TestGeospatialMethods_TableATemp JOIN TestGeospatialMethods_TableBTemp ON @referencePoint.STDisjoint(TestGeospatialMethods_TableBTemp.PointB) = 1 ORDER BY TestGeospatialMethods_TableBTemp.PointB.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointA.STAsText(),PointB.STAsText() FROM TestGeospatialMethods_TableATemp JOIN TestGeospatialMethods_TableBTemp ON PointA.STDisjoint(@referencePoint) = 1 ORDER BY TestGeospatialMethods_TableBTemp.PointB.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointA.STAsText(),PointB.STAsText() FROM TestGeospatialMethods_TableATemp JOIN TestGeospatialMethods_TableBTemp ON TestGeospatialMethods_TableBTemp.PointB.STDisjoint(@referencePoint) = 0 ORDER BY PointB.STX;
go

-- Use in a CASE Statement
DECLARE @disjoints BIT = 1 ;
SELECT ID, PointColumn1.STDisjoint(PointColumn2) AS dodisjoint,
CASE WHEN PointColumn1.STDisjoint(PointColumn2) = @disjoints THEN 'Disjoints' ELSE 'Are_not_disjoint'
END AS Proximity
FROM TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn1.STDisjoint(@referencePoint) AS disjoint,
CASE WHEN @referencePoint.STDisjoint(PointColumn2) = @referencePoint.STX THEN 'Disjoints' ELSE 'Are_not_disjoint'
END AS Proximity
FROM TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

--Use in a CTE (Common Table Expression)
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH CTE AS ( SELECT ID, PointColumn.STDisjoint(@referencePoint) AS disjoint FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX)
SELECT * FROM CTE WHERE disjoint = 1 ORDER BY disjoint;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH CTE AS ( SELECT ID, @referencePoint.STDisjoint(PointColumn) AS disjoint FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX)
SELECT * FROM CTE WHERE disjoint = 1 ORDER BY disjoint;
go

--Use in a Conditional Statement
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @disjoints BIT = 1;
SELECT ID, PointColumn.STDisjoint(@referencePoint) AS ReferencePoint,
CASE WHEN PointColumn.STDisjoint(@referencePoint) = @disjoints THEN 'disjoint'
ELSE 'are_not_disjoint'
END AS Proximity
FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, @referencePoint.STDisjoint(PointColumn) AS ReferencePoint,
CASE WHEN @referencePoint.STDisjoint(PointColumn) = @referencePoint.STY THEN 'disjoint'
ELSE 'are_not_disjoint'
END AS Proximity
FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

--Use in a Pivot Query
DECLARE @Ranges TABLE (MinDistance float, MaxDistance float);
INSERT INTO @Ranges VALUES (0, 5), (5, 10), (10, 15);
SELECT * FROM ( SELECT ID,
CASE WHEN PointColumn1.STDisjoint(PointColumn2) BETWEEN 0 AND 1 THEN 'disjoint'
ELSE 'do_not_disjoint'
END AS Range
FROM TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX
) AS Source
PIVOT ( COUNT(ID) FOR Range IN ([0-5], [5.1-10], [10.1-15], [15.1+])) AS PivotTable;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STDisjoint(@referencePoint) AS disjoint FROM TestGeospatialMethods_DB.dbo.TestGeospatialMethods_YourTable1Temp ORDER BY PointColumn.STX;
go

--Use in a JSON Output
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STDisjoint(@referencePoint) AS disjoint,
JSON_QUERY('{"Disjoint":' + CAST(PointColumn.STDisjoint(@referencePoint) AS NVARCHAR(MAX)) + '}') AS Json
FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, @referencePoint.STDisjoint(PointColumn) AS disjoint,
JSON_QUERY('{"Disjoint":' + CAST(@referencePoint.STDisjoint(PointColumn) AS NVARCHAR(MAX)) + '}') Json
FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

-- Using Square brackets '[]' identifier
SELECT [PointColumn1].STDisjoint([PointColumn2]) AS disjoint FROM TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

--Use in Prepared Statement
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @disjoints BIT = 1;
DECLARE @sql NVARCHAR(MAX);
DECLARE @params NVARCHAR(MAX);
SET @sql = N'
SELECT ID, PointColumn.STDisjoint(@referencePoint) AS IntersectingReferancePoint,
CASE WHEN PointColumn.STDisjoint(@referencePoint) = @disjoints THEN ''disjoints''
ELSE ''do_not_disjoint''
END AS Proximity
FROM TestGeospatialMethods_YourTableTemp
WHERE PointColumn.STDisjoint(@referencePoint) = @disjoints;';
SET @params = N'@referencePoint geometry, @disjoints float';
EXEC sp_executesql @sql, @params, @referencePoint, @disjoints;
go

--Use in Multi-Part column name Statements
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STDisjoint(@referencePoint) AS disjoint FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
SELECT TestGeospatialMethods_YourTableTemp.PointColumn.STDisjoint(@referencePoint) AS disjoint FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
SELECT TestGeospatialMethods_YourTableTemp.PointColumn.STDisjoint(@referencePoint) AS disjoint FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

--Use in function.STDisjoint(@point) Statements
DECLARE @pnt geometry;
SET @pnt = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
select geometry::Point(@pnt.STY, @pnt.STX, 4326).STDisjoint(@pnt)

--Use in a Group By Clause
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @disjoints BIT = 1;
SELECT ROUND(PointColumn.STDisjoint(@referencePoint) / @disjoints, 0) * @disjoints AS Grp,
COUNT(*) AS PointCount
FROM TestGeospatialMethods_YourTableTemp
GROUP BY ROUND(PointColumn.STDisjoint(@referencePoint) / @disjoints, 0) * @disjoints
ORDER BY Grp;
go

DECLARE @referencePoint geometry = geometry::Point(1.0, 0.0, 4326);
SELECT ROUND(PointColumn.STDisjoint(@referencePoint) / @referencePoint.STX, 0) * @referencePoint.STX AS GRP,
COUNT(*) AS PointCount
FROM TestGeospatialMethods_YourTableTemp
GROUP BY ROUND(PointColumn.STDisjoint(@referencePoint) / @referencePoint.STX, 0) * @referencePoint.STX
ORDER BY Grp;
go

--Use in a Window Function
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn1.STDisjoint(PointColumn2) AS disjoint,
cast(PointColumn1.STDisjoint(@referencePoint) as int) - LAG(PointColumn1.STDisjoint(PointColumn2)) OVER (ORDER BY ID) AS Difference 
FROM TestGeospatialMethods_YourTable2Temp ORDER BY PointColumn1.STX;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STDisjoint(@referencePoint) AS disjoint,
cast(@referencePoint.STDisjoint(PointColumn) as int) - LAG(@referencePoint.STX) OVER (ORDER BY ID) AS Difference
FROM TestGeospatialMethods_YourTableTemp ORDER BY PointColumn.STX;
go

--Use in an UPDATE Statement
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326); 
UPDATE TestGeospatialMethods_YourTableTemp SET PointColumn = @referencePoint
WHERE @referencePoint.STDisjoint(PointColumn) = 1;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326); 
UPDATE TestGeospatialMethods_YourTableTemp SET PointColumn = @referencePoint
WHERE PointColumn.STDisjoint(@referencePoint) != 1;
go

--Cross-database query to retrieve disjoints
DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STDisjoint(@referencePoint) AS Disjoint FROM TestGeospatialMethods_DB.dbo.TestGeospatialMethods_YourTable1Temp;
go

--Negative test for Geospatial functions
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

--not compatible with sql server as well
--Combining geometry and geography in a single query
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

--STDimension

DECLARE @g geometry; 
SELECT @g.STDimension(); 
go

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STDimension(@point);
go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
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

SELECT location.STDimension() from TestGeospatialMethods_SPATIALPOINTGEOM_dttemp ORDER BY location.STX;
go

SELECT location.STDimension() from TestGeospatialMethods_SPATIALPOINTGEOG_dttemp ORDER BY location.Lat;
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

--STIsEmpty

DECLARE @g geometry;  
SET @g = geometry::STGeomFromText('POINT EMPTY', 0);  
SELECT @g.STIsEmpty();

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STIsEmpty(@point);
go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
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

SELECT location.STIsEmpty() from TestGeospatialMethods_SPATIALPOINTGEOM_dttemp ORDER BY location.STX;
go

SELECT location.STIsEmpty() from TestGeospatialMethods_SPATIALPOINTGEOG_dttemp ORDER BY location.Lat;
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

--STIsValid

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STIsValid(@point);
go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
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

SELECT location.STIsValid() from TestGeospatialMethods_SPATIALPOINTGEOM_dttemp ORDER BY location.STX;
go

SELECT location.STIsValid() from TestGeospatialMethods_SPATIALPOINTGEOG_dttemp ORDER BY location.Lat;
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

--STIsClosed

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STIsClosed(@point);
go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
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

SELECT location.STIsClosed() from TestGeospatialMethods_SPATIALPOINTGEOM_dttemp ORDER BY location.STX;
go

SELECT location.STIsClosed() from TestGeospatialMethods_SPATIALPOINTGEOG_dttemp ORDER BY location.Lat;
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