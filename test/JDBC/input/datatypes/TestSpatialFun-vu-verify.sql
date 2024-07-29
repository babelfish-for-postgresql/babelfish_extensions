-- For STEquals
DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
DECLARE @point2 geometry = geometry::Point(3.0, 4.0, 4326);
SELECT @point1.STEquals(@point2) AS Equal;
go

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
DECLARE @point2 geometry = geometry::Point(3.0, 4.0, 4326);
SELECT STEquals(@point1, @point2);
go

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
DECLARE @point2 geometry = geometry::Point(3.0, 4.0, 4326);
SELECT @point1 . STEquals ( @point2 );
go

SELECT PointColumn1.STEquals(PointColumn2) AS Equals FROM YourTableTemp2;
go

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
SELECT PointColumn1.STEquals(@point1) AS Equals FROM YourTableTemp2;
go

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
SELECT @point1.STEquals(PointColumn2) AS Equals FROM YourTableTemp2;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @isEqual BIT = 1;
SELECT * FROM YourTableTemp WHERE PointColumn.STEquals(@referencePoint) = @isEqual;
go

SELECT ID, PointColumn1.STEquals(PointColumn2) AS Equal_points FROM YourTableTemp2;
go

SELECT * FROM TableATemp JOIN TableBTemp ON PointA.STEquals(TableBTemp.PointB) <= 1;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT * FROM TableATemp JOIN TableBTemp ON @referencePoint.STEquals(TableBTemp.PointB) <= 1;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT * FROM TableATemp JOIN TableBTemp ON PointA.STEquals(@referencePoint) <= 1;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT * FROM YourTableTemp ORDER BY @referencePoint.STEquals(PointColumn);
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT * FROM YourTableTemp ORDER BY PointColumn.STEquals(@referencePoint);
go

SELECT * FROM YourTableTemp2 ORDER BY PointColumn1.STEquals(PointColumn2);
go

DECLARE @isEqual BIT = 1;
SELECT ID, PointColumn1.STEquals(PointColumn2) AS isEqual,
CASE WHEN PointColumn1.STEquals(PointColumn2) = @isEqual THEN 'yes' ELSE 'no'
END AS isEqual
FROM YourTableTemp2;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH EqualCTE AS ( SELECT ID, PointColumn.STEquals(@referencePoint) AS Equality FROM YourTableTemp)
SELECT * FROM EqualCTE WHERE Equality <= 1;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326); 
UPDATE YourTableTemp SET PointColumn = @referencePoint
WHERE PointColumn.STEquals(@referencePoint) != 1;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326); 
UPDATE YourTableTemp SET PointColumn = @referencePoint
WHERE @referencePoint.STEquals(PointColumn) = 1;
go


DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH EqualCTE AS ( SELECT ID, PointColumn.STEquals(@referencePoint) AS Equal FROM YourTableTemp ORDER BY PointColumn.STX)
SELECT * FROM EqualCTE WHERE Equal <= 1.0 ORDER BY Equal;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH EqualCTE AS ( SELECT ID, @referencePoint.STEquals(PointColumn) AS Equal FROM YourTableTemp ORDER BY PointColumn.STX)
SELECT * FROM EqualCTE WHERE Equal <= 1.0 ORDER BY Equal;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @isEqual BIT = 1;
SELECT ID, PointColumn.STEquals(@referencePoint) AS EqualityReferencePoint,
CASE WHEN PointColumn.STEquals(@referencePoint) <= @isEqual THEN 'Close'
ELSE 'Far'
END AS Proximity
FROM YourTableTemp;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, @referencePoint.STEquals(PointColumn) AS EqualityReferencePoint,
CASE WHEN @referencePoint.STEquals(PointColumn) <= @referencePoint.STY THEN 'Close'
ELSE 'Far'
END AS Proximity
FROM YourTableTemp;
go

DECLARE @Ranges TABLE (MinDistance float, MaxDistance float);
INSERT INTO @Ranges VALUES (0, 5), (5, 10), (10, 15);
SELECT * FROM ( SELECT ID,
CASE WHEN PointColumn1.STEquals(PointColumn2) BETWEEN 0 AND 1 THEN 'yes'
ELSE 'no'
END AS Range
FROM YourTableTemp2
) AS Source
PIVOT ( COUNT(ID) FOR Range IN ([0-5], [5.1-10], [10.1-15], [15.1+])) AS PivotTable;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STEquals(@referencePoint) AS Equality FROM <YourDatabase>.dbo.YourTableTemp;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STEquals(@referencePoint) AS Equal,
JSON_QUERY('{"Equal":' + CAST(PointColumn.STEquals(@referencePoint) AS NVARCHAR(MAX)) + '}') AS Json
FROM YourTableTemp;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, @referencePoint.STEquals(PointColumn) AS Equal,
JSON_QUERY('{"Equal":' + CAST(@referencePoint.STEquals(PointColumn) AS NVARCHAR(MAX)) + '}') Json
FROM YourTableTemp;
go

SELECT [PointColumn1].STEquals([PointColumn2]) AS Equality FROM [YourTableTemp2];
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @isEqual BIT = 1;
DECLARE @sql NVARCHAR(MAX);
DECLARE @params NVARCHAR(MAX);
SET @sql = N'
SELECT ID, PointColumn.STEquals(@referencePoint) AS EqualityReferencePoint,
CASE WHEN PointColumn.STEquals(@referencePoint) <= @isEqual THEN ''Close''
ELSE ''Far''
END AS Proximity
FROM YourTableTemp
WHERE PointColumn.STEquals(@referencePoint) <= @isEqual;';
SET @params = N'@referencePoint geometry, @isEqual float';
EXEC sp_executesql @sql, @params, @referencePoint, @isEqual;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STEquals(@referencePoint) AS Equality FROM YourTableTemp;
SELECT YourTableTemp.PointColumn.STEquals(@referencePoint) AS Equality FROM YourTableTemp;
SELECT dbo.YourTableTemp.PointColumn.STEquals(@referencePoint) AS Equality FROM YourTableTemp;
go

DECLARE @pnt geometry;
SET @pnt = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
select geometry::Point(@pnt.STY, @pnt.STX, 4326).STEquals(@pnt)
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @equal BIT = 1;
SELECT ROUND(PointColumn.STEquals(@referencePoint) / @equal, 0) * @equal AS Equalitygroup,
COUNT(*) AS PointCount
FROM YourTableTemp
GROUP BY ROUND(PointColumn.STEquals(@referencePoint) / @equal, 0) * @equal
ORDER BY Equalitygroup;
GO

DECLARE @referencePoint geometry = geometry::Point(1.0, 0.0, 4326);
SELECT ROUND(PointColumn.STEquals(@referencePoint) / @referencePoint.STX, 0) * @referencePoint.STX AS Equalitygroup,
COUNT(*) AS PointCount
FROM YourTableTemp
GROUP BY ROUND(PointColumn.STEquals(@referencePoint) / @referencePoint.STX, 0) * @referencePoint.STX
ORDER BY Equalitygroup;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn1.STEquals(PointColumn2) AS equal,
cast(PointColumn1.STEquals(@referencePoint) as float) - LAG(PointColumn1.STEquals(PointColumn2)) OVER (ORDER BY ID) AS Equalitygroup 
FROM YourTableTemp2 ORDER BY PointColumn1.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STEquals(@referencePoint) AS equal,
cast(@referencePoint.STContains(PointColumn) as float) - LAG(@referencePoint.STX) OVER (ORDER BY ID) AS Equalitygroup
FROM YourTableTemp ORDER BY PointColumn.STX;
GO




--For STContains

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geometry::STGeomFromText('POINT(-122.35000 47.65000)', 4326);
SELECT STContains(@point1, @point2);
go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geometry::STGeomFromText('POINT(-122.35000 47.65000)', 4326);
SELECT @point1.STContains(@point2);
go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geometry::STGeomFromText('POINT(-122.35000 47.65000)', 4326);
SELECT @point1 . STContains ( @point2 );
Go

SELECT ID, PointColumn1.STContains(PointColumn2) AS contain FROM YourTableTemp2 ORDER BY PointColumn1.STX;
GO

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
SELECT ID, PointColumn1.STContains(@point1) AS contain FROM YourTableTemp2 ORDER BY PointColumn1.STX;
GO

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
SELECT ID, @point1.STContains(PointColumn2) AS contain FROM YourTableTemp2 ORDER BY PointColumn1.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @contain BIT = 1;
SELECT * FROM YourTableTemp WHERE PointColumn.STContains(@referencePoint) <= @contain ORDER BY PointColumn.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT * FROM YourTableTemp WHERE @referencePoint.STContains(PointColumn) <= @referencePoint.STX ORDER BY PointColumn.STX;
GO

SELECT ID, PointColumn1.STContains(PointColumn2) AS contain FROM YourTableTemp2;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT * FROM YourTableTemp WHERE PointColumn.STContains(@referencePoint) != @referencePoint.STX ORDER BY PointColumn.STX;
GO

SELECT * FROM TableATemp JOIN TableBTemp ON PointA.STContains(TableBTemp.PointB) = 1 ORDER BY TableBTemp.PointB.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT * FROM TableATemp JOIN TableBTemp ON @referencePoint.STContains(TableBTemp.PointB) = 1 ORDER BY TableBTemp.PointB.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT * FROM TableATemp JOIN TableBTemp ON PointA.STContains(@referencePoint) = 1 ORDER BY TableBTemp.PointB.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT * FROM TableATemp JOIN TableBTemp ON TableBTemp.PointB.STContains(@referencePoint) = 0 ORDER BY TableBTemp.PointB.STX;
GO

SELECT * FROM YourTableTemp2 ORDER BY PointColumn1.STContains(PointColumn2);
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT * FROM YourTableTemp ORDER BY PointColumn.STContains(@referencePoint);
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT * FROM YourTableTemp ORDER BY @referencePoint.STContains(PointColumn);
GO

DECLARE @contains BIT = 1 ;
SELECT ID, PointColumn1.STContains(PointColumn2) AS doContain,
CASE WHEN PointColumn1.STContains(PointColumn2) <= @contains THEN 'Contains' ELSE 'Do_not_contain'
END AS Proximity
FROM YourTableTemp2 ORDER BY PointColumn1.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn1.STContains(@referencePoint) AS contain,
CASE WHEN @referencePoint.STContains(PointColumn2) <= @referencePoint.STX THEN 'Contains' ELSE 'Do_not_contain'
END AS Proximity
FROM YourTableTemp2 ORDER BY PointColumn1.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH CTE AS ( SELECT ID, PointColumn.STContains(@referencePoint) AS contain FROM YourTableTemp ORDER BY PointColumn.STX)
SELECT * FROM CTE WHERE contain = 1 ORDER BY contain;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH CTE AS ( SELECT ID, @referencePoint.STContains(PointColumn) AS contain FROM YourTableTemp ORDER BY PointColumn.STX)
SELECT * FROM CTE WHERE contain = 1 ORDER BY contain;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @contains BIT = 1;
SELECT ID, PointColumn.STContains(@referencePoint) AS ReferencePoint,
CASE WHEN PointColumn.STContains(@referencePoint) <= @contains THEN 'contain'
ELSE 'do_not_contain'
END AS Proximity
FROM YourTableTemp;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, @referencePoint.STContains(PointColumn) AS ReferencePoint,
CASE WHEN @referencePoint.STContains(PointColumn) <= @referencePoint.STY THEN 'contain'
ELSE 'do_not_contain'
END AS Proximity
FROM YourTableTemp;
go

DECLARE @Ranges TABLE (MinDistance float, MaxDistance float);
INSERT INTO @Ranges VALUES (0, 5), (5, 10), (10, 15);
SELECT * FROM ( SELECT ID,
CASE WHEN PointColumn1.STContains(PointColumn2) BETWEEN 0 AND 1 THEN 'contain'
ELSE 'do_not_contain'
END AS Range
FROM YourTableTemp2
) AS Source
PIVOT ( COUNT(ID) FOR Range IN ([0-5], [5.1-10], [10.1-15], [15.1+])) AS PivotTable;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STContains(@referencePoint) AS contain FROM <YourDatabase>.dbo.YourTableTemp;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STContains(@referencePoint) AS contain,
JSON_QUERY('{"Contain":' + CAST(PointColumn.STContains(@referencePoint) AS NVARCHAR(MAX)) + '}') AS Json
FROM YourTableTemp;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, @referencePoint.STContains(PointColumn) AS contain,
JSON_QUERY('{"Contain":' + CAST(@referencePoint.STContains(PointColumn) AS NVARCHAR(MAX)) + '}') Json
FROM YourTableTemp;
go

SELECT [PointColumn1].STContains([PointColumn2]) AS contain FROM [YourTableTemp2];
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @contains BIT = 1;
DECLARE @sql NVARCHAR(MAX);
DECLARE @params NVARCHAR(MAX);
SET @sql = N'
SELECT ID, PointColumn.STContains(@referencePoint) AS EqualityReferencePoint,
CASE WHEN PointColumn.STContains(@referencePoint) <= @contains THEN ''contains''
ELSE ''do_not_contain''
END AS Proximity
FROM YourTableTemp
WHERE PointColumn.STContains(@referencePoint) <= @contains;';
SET @params = N'@referencePoint geometry, @contains float';
EXEC sp_executesql @sql, @params, @referencePoint, @contains;
go

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STContains(@referencePoint) AS contain FROM YourTableTemp;
SELECT YourTableTemp.PointColumn.STContains(@referencePoint) AS contain FROM YourTableTemp;
SELECT dbo.YourTableTemp.PointColumn.STContains(@referencePoint) AS contain FROM YourTableTemp;
go

DECLARE @pnt geometry;
SET @pnt = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
select geometry::Point(@pnt.STY, @pnt.STX, 4326).STContains(@pnt)

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @contains BIT = 1;
SELECT ROUND(PointColumn.STContains(@referencePoint) / @contains, 0) * @contains AS Grp,
COUNT(*) AS PointCount
FROM YourTableTemp
GROUP BY ROUND(PointColumn.STContains(@referencePoint) / @contains, 0) * @contains
ORDER BY Grp;
GO

DECLARE @referencePoint geometry = geometry::Point(1.0, 0.0, 4326);
SELECT ROUND(PointColumn.STContains(@referencePoint) / @referencePoint.STX, 0) * @referencePoint.STX AS GRP,
COUNT(*) AS PointCount
FROM YourTableTemp
GROUP BY ROUND(PointColumn.STContains(@referencePoint) / @referencePoint.STX, 0) * @referencePoint.STX
ORDER BY Grp;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn1.STContains(PointColumn2) AS contain,
cast(PointColumn1.STContains(@referencePoint) as float) - LAG(PointColumn1.STContains(PointColumn2)) OVER (ORDER BY ID) AS Difference 
FROM YourTableTemp2 ORDER BY PointColumn1.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STContains(@referencePoint) AS contain,
cast(@referencePoint.STContains(PointColumn) as float) - LAG(@referencePoint.STX) OVER (ORDER BY ID) AS Difference
FROM YourTableTemp ORDER BY PointColumn.STX;
GO

--for STArea

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STArea(@point);
go

DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point.STArea();
Go

DECLARE @point geometry;
SET @point = geometry::POINT(22.34900, -47.65100, 4326);
SELECT @point . STArea ( );
Go

SELECT location.STArea() from SPATIALPOINTGEOM_dttemp ORDER BY location.STX;
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
SET @point1 = geometry::Point(22.34900, -47.65100, 4326);;
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

SELECT location.STArea() from SPATIALPOINTGEOG_dttemp ORDER BY location.Lat;
GO