-- sla_for_parallel_query_enforced 60000
-- single_db_mode_expected
DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STAsText(@point);
SELECT @point.STAsText();
Go

DECLARE @point geometry;
SET @point = geometry::POINT(22.34900, -47.65100, 4326);
SELECT STAsText(@point);
SELECT @point.STAsText();
SELECT @point . STAsText ( );
Go

DECLARE @point geometry; 
SET @point = geometry::Point(1.0, 2.0, 4326); 
SELECT @point.STX AS XCoordinate;
GO

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
DECLARE @point2 geometry = geometry::Point(3.0, 4.0, 4326);
SELECT @point1.STDistance(@point2) AS Distance;
GO

DECLARE @point geometry;
SET @point = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STX(@point);
SELECT STY(@point);
SELECT @point.STX;
SELECT @point.STY;
Go

DECLARE @point geometry;
SET @point = geometry::Point(22.34900, -47.65100, 4326);
SELECT STX(@point);
SELECT STY(@point);
SELECT @point.STX;
SELECT @point . STX;
SELECT @point.STY;
Go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geometry::STGeomFromText('POINT(-122.35000 47.65000)', 4326);
SELECT STDistance(@point1, @point2);
SELECT @point1.STDistance(@point2);
SELECT @point1 . STDistance ( @point2 );
Go

DECLARE @point geometry;
SET @point = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
Insert INTO SPATIALPOINTGEOM_dt(location) VALUES(geometry::point(@point.STX, @point.STY,4326))
go

DECLARE @STX geometry;
SET @STX = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
select geometry::Point(@STX.STX, @STX.STY, 4326).STX, geometry::Point(@STX.STX, @STX.STY, 4326).STY;
go

DECLARE @STX geometry;
SET @STX = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
select geometry::Point(@STX.STX, @STX.STY, 4326).STAsText(), geometry::Point(@STX.STX, @STX.STY, 4326).STAsBinary(), geometry::Point(@STX.STX, @STX.STY, 4326).STDistance(geometry::Point(@STX.STX, @STX.STY, 4326));
go

-- Null test for Geospatial functions
DECLARE @point1 geometry, @point2 geometry, @point3 geometry;
SET @point1 = geometry::STPointFromText(null, 4326);
SET @point2 = geometry::STGeomFromText(null, 4326);
SET @point3 = geometry::Point(22.34900, -47.65100, 4326);
SELECT @point1.STX;
SELECT @point1.STY;
SELECT @point1.STAsText();
SELECT @point1.STAsBinary();
SELECT @point1.STDistance(@point2);
SELECT @point3.STDistance(@point2);
SELECT @point1.STDistance(@point3);
Go

-- Negative test for Geospatial functions
DECLARE @point1 geometry, @point2 varchar(50), @point3 int;
SET @point1 = geometry::Point(22.34900, -47.65100, 4326);;
SET @point2 = 'Test_String';
SELECT @point1.STDistance(@point2);
Go

SELECT location.Lat from SPATIALPOINTGEOM_dt ORDER BY location.STX;
GO

SELECT * FROM GeomView ORDER BY Coordinates;
GO

select * from geominTable ORDER BY a.STX;
GO

SELECT * FROM ValFromGeom ORDER BY binary;
GO

EXEC dbo.p_getcoordinates;
GO

geominTest 'POINT(1 2)'
GO

geominTest 'POINT(1 200)'
GO

geominTest 'POINT(1000 20)'
GO

SELECT * FROM TextFromGeom ORDER BY XCoord;
GO

SELECT * FROM BinaryFromGeom ORDER BY BinaryRepresentation;
GO

SELECT * FROM CoordsFromGeom ORDER BY Coordinates;
GO

SELECT * FROM equal_geom ORDER BY point.STX;
GO

SELECT * FROM point_distances_geom ORDER BY distance;
GO

SELECT location.STX from SPATIALPOINTGEOM_dt ORDER BY location.STX;
GO

SELECT SPATIALPOINTGEOM_dt.location.STY from SPATIALPOINTGEOM_dt ORDER BY location.STX;
GO

SELECT location.STAsText() from SPATIALPOINTGEOM_dt ORDER BY location.STX;
GO

SELECT location.STAsBinary() from SPATIALPOINTGEOM_dt ORDER BY location.STX;
GO

SELECT location.STDistance(geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326)) from SPATIALPOINTGEOM_dt ORDER BY location.STX;
GO

SELECT [SPATIALPOINTGEOM_dt].[location].[STX] from [SPATIALPOINTGEOM_dt] ORDER BY location.STX;
GO

SELECT [location].[STY] from [SPATIALPOINTGEOM_dt] ORDER BY location.STX;
GO

SELECT location FROM SPATIALPOINTGEOM_dt ORDER BY location.STX; 
GO

SELECT PointColumn.STX AS XCoordinate FROM YourTable ORDER BY PointColumn.STX;
GO

SELECT * FROM YourTable WHERE PointColumn.STX > 3.0 ORDER BY PointColumn.STX;
GO

DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT * FROM YourTable WHERE PointColumn.STX > @point.STX ORDER BY PointColumn.STX;
GO

SELECT ID, PointColumn.STX AS XCoordinate FROM YourTable ORDER BY PointColumn.STX;
GO

SELECT ID, dbo.GetXCoordinate(PointColumn) AS XCoordinate FROM YourTable ORDER BY PointColumn.STX;
GO

DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT dbo.GetXCoordinate(@point);
GO

SELECT * FROM TableA JOIN TableB ON TableA.PointA.STX = TableB.PointB.STX ORDER BY TableA.PointA.STX;
GO

DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT * FROM TableA JOIN TableB ON TableA.PointA.STX > @point.STX ORDER BY TableA.PointA.STX;
GO

SELECT * FROM YourTable ORDER BY PointColumn.STX;
GO

DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT * FROM YourTable ORDER BY @point.STX;
GO

SELECT ID, PointColumn.STX AS XCoordinate,
CASE WHEN PointColumn.STX > 3.0 THEN 'High X' 
ELSE 'Low X' 
END AS XCoordinateCategory FROM YourTable ORDER BY PointColumn.STX;
GO

DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT ID, PointColumn.STX AS XCoordinate,
CASE WHEN @point.STX > 3.0 THEN 'High X' 
ELSE 'Low X' 
END AS XCoordinateCategory FROM YourTable ORDER BY PointColumn.STX;
GO

WITH PointData AS ( SELECT ID, PointColumn.STX AS XCoordinate FROM YourTable ORDER BY PointColumn.STX ) 
SELECT * FROM PointData WHERE XCoordinate > 3.0 ORDER BY XCoordinate;
GO

DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
WITH PointData AS ( SELECT ID, @point.STX AS XCoordinate FROM YourTable ORDER BY PointColumn.STX )
SELECT * FROM PointData WHERE XCoordinate > 3.0 ORDER BY XCoordinate;
GO

SELECT PointColumn.STX AS XCoordinate, COUNT(*) AS PointCount 
FROM GeomTab GROUP BY PointColumn.STX ORDER BY PointColumn.STX;
GO

DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT @point.STX AS XCoordinate, COUNT(*) AS PointCount 
FROM YourTable GROUP BY PointColumn.STX ORDER BY PointColumn.STX;
GO

SELECT ID, PointColumn.STX AS XCoordinate, 
PointColumn.STX - LAG(PointColumn.STX) OVER (ORDER BY ID) AS XCoordinateDifference 
FROM YourTable ORDER BY PointColumn.STX;
GO

DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT ID, @point.STX AS XCoordinate, 
@point.STX - LAG(@point.STX) OVER (ORDER BY ID) AS XCoordinateDifference 
FROM YourTable ORDER BY PointColumn.STX;
GO

DECLARE @XCoordinate FLOAT = 3.0;
DECLARE @DynamicQuery NVARCHAR(MAX);
SET @DynamicQuery = N' SELECT * FROM YourTable WHERE PointColumn.STX > ' + CAST(@XCoordinate AS NVARCHAR(MAX)) + ' ORDER BY PointColumn.STX';
EXEC sp_executesql @DynamicQuery;
GO

DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
DECLARE @DynamicQuery NVARCHAR(MAX);
SET @DynamicQuery = N' SELECT * FROM YourTable WHERE PointColumn.STX > ' + CAST(@point.STX AS NVARCHAR(MAX)) + ' ORDER BY PointColumn.STX';
EXEC sp_executesql @DynamicQuery;
GO

EXEC GetDistanceByXCoordinate @xCoordinate = 6.0;
GO

EXEC GetPointsByXCoordinate @XCoordinate = 4.0;
GO

EXEC GetPointsByXCoordinate1 @XCoordinate = 4.0;
GO

DECLARE @XCoordinate FLOAT = 3.0; 
DECLARE @DynamicQuery NVARCHAR(MAX); 
SET @DynamicQuery = N' SELECT * FROM YourTable WHERE PointColumn.STX > ' + CAST(@XCoordinate AS NVARCHAR(MAX)) + ' ORDER BY PointColumn.STX'; 
EXEC sp_executesql @DynamicQuery;
GO

SELECT ID, PointColumn.STX AS XCoordinate, CASE WHEN PointColumn.STX < 0 
THEN 'Negative X' WHEN PointColumn.STX = 0 THEN 'Zero X' 
ELSE 'Positive X' END AS XCoordinateCategory FROM YourTable ORDER BY PointColumn.STX;
GO

DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT ID, @point.STX AS XCoordinate, CASE WHEN @point.STX < 0 
THEN 'Negative X' WHEN @point.STX = 0 THEN 'Zero X' 
ELSE 'Positive X' END AS XCoordinateCategory FROM YourTable ORDER BY PointColumn.STX;
GO

SELECT * FROM ( SELECT ID,
CASE WHEN PointColumn.STX BETWEEN 0 AND 5 THEN '0-5'
WHEN PointColumn.STX BETWEEN 5.1 AND 10 THEN '5.1-10'
ELSE '10.1+'
END AS XCoordRange
FROM YourTable ORDER BY PointColumn.STX
) AS Source
PIVOT ( COUNT(ID) FOR XCoordRange IN ([0-5], [5.1-10], [10.1+])) AS PivotTable;
GO

SELECT ID, PointColumn.STX AS XCoordinate,
JSON_QUERY('{"XCoordinate":' + CAST(PointColumn.STX AS NVARCHAR(MAX)) + '}') AS XCoordinateJson 
FROM YourTable ORDER BY PointColumn.STX;
GO

DECLARE @point geometry = geometry::Point(3.0, 2.0, 4326);
SELECT ID, @point.STX AS XCoordinate,
JSON_QUERY('{"XCoordinate":' + CAST(@point.STX AS NVARCHAR(MAX)) + '}') AS XCoordinateJson 
FROM YourTable ORDER BY PointColumn.STX;
GO

SELECT [PointColumn].[STX] AS XCoordinate FROM [YourTable] ORDER BY PointColumn.STX;
GO

DECLARE @point geometry = geometry::Point(3.0, 2.0, 4326);
SELECT @point.[STX] AS XCoordinate
GO

SELECT PointColumn.STX AS XCoordinate FROM YourTable ORDER BY PointColumn.STX;
GO

SELECT YourTable.PointColumn.STX AS XCoordinate FROM YourTable ORDER BY PointColumn.STX;
GO

SELECT dbo.YourTable.PointColumn.STX AS XCoordinate FROM YourTable ORDER BY PointColumn.STX;
GO

SELECT YourTable1.STX.STX AS XCoordinate FROM YourTable1 ORDER BY STX.STX;
GO

DECLARE @result geometry;
SET @result = dbo.GetGeometry();
DECLARE @xCoordinate float;
SET @xCoordinate = @result.STX;
SELECT @result AS ResultGeometry, @xCoordinate AS XCoordinate ORDER BY XCoordinate;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326); 
UPDATE YourTable SET PointColumn = @referencePoint
WHERE PointColumn.STX >= @referencePoint.STX;
GO

SELECT ID, PointColumn1.STDistance(PointColumn2) AS Distance FROM YourTable2 ORDER BY PointColumn1.STX;
GO

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
SELECT ID, PointColumn1.STDistance(@point1) AS Distance FROM YourTable2 ORDER BY PointColumn1.STX;
GO

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
SELECT ID, @point1.STDistance(PointColumn2) AS Distance FROM YourTable2 ORDER BY PointColumn1.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @maxDistance float = 5.0;
SELECT * FROM YourTable WHERE PointColumn.STDistance(@referencePoint) <= @maxDistance ORDER BY PointColumn.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT * FROM YourTable WHERE @referencePoint.STDistance(PointColumn) <= @referencePoint.STX ORDER BY PointColumn.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT * FROM YourTable WHERE PointColumn.STDistance(@referencePoint) <= @referencePoint.STX ORDER BY PointColumn.STX;
GO

SELECT ID, dbo.CalculateDistance(PointColumn1, PointColumn2) AS Distance FROM YourTable2 ORDER BY PointColumn1.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, dbo.CalculateDistance(@referencePoint, PointColumn2) AS Distance FROM YourTable2 ORDER BY PointColumn1.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, dbo.CalculateDistance(PointColumn1, @referencePoint) AS Distance FROM YourTable2 ORDER BY PointColumn1.STX;
GO

SELECT * FROM TableA JOIN TableB ON PointA.STDistance(TableB.PointB) <= 5.0 ORDER BY TableB.PointB.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT * FROM TableA JOIN TableB ON @referencePoint.STDistance(TableB.PointB) <= 5.0 ORDER BY TableB.PointB.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT * FROM TableA JOIN TableB ON PointA.STDistance(@referencePoint) <= 5.0 ORDER BY TableB.PointB.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT * FROM TableA JOIN TableB ON TableB.PointB.STDistance(@referencePoint) <= 5.0 ORDER BY TableB.PointB.STX;
GO

SELECT * FROM YourTable2 ORDER BY PointColumn1.STDistance(PointColumn2);
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT * FROM YourTable ORDER BY PointColumn.STDistance(@referencePoint);
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT * FROM YourTable ORDER BY @referencePoint.STDistance(PointColumn);
GO

DECLARE @thresholdDistance float = 3.0;
SELECT ID, PointColumn1.STDistance(PointColumn2) AS DistanceBetweenPoints,
CASE WHEN PointColumn1.STDistance(PointColumn2) <= @thresholdDistance THEN 'Close' ELSE 'Far'
END AS Proximity
FROM YourTable2 ORDER BY PointColumn1.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn1.STDistance(@referencePoint) AS DistanceBetweenPoints,
CASE WHEN @referencePoint.STDistance(PointColumn2) <= @referencePoint.STX THEN 'Close' ELSE 'Far'
END AS Proximity
FROM YourTable2 ORDER BY PointColumn1.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH DistanceCTE AS ( SELECT ID, PointColumn.STDistance(@referencePoint) AS Distance FROM YourTable ORDER BY PointColumn.STX)
SELECT * FROM DistanceCTE WHERE Distance <= 3.0 ORDER BY Distance;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
WITH DistanceCTE AS ( SELECT ID, @referencePoint.STDistance(PointColumn) AS Distance FROM YourTable ORDER BY PointColumn.STX)
SELECT * FROM DistanceCTE WHERE Distance <= 3.0 ORDER BY Distance;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @distanceInterval float = 5.0;
SELECT ROUND(PointColumn.STDistance(@referencePoint) / @distanceInterval, 0) * @distanceInterval AS DistanceGroup,
COUNT(*) AS PointCount
FROM YourTable
GROUP BY ROUND(PointColumn.STDistance(@referencePoint) / @distanceInterval, 0) * @distanceInterval
ORDER BY DistanceGroup;
GO

DECLARE @referencePoint geometry = geometry::Point(1.0, 0.0, 4326);
SELECT ROUND(PointColumn.STDistance(@referencePoint) / @referencePoint.STX, 0) * @referencePoint.STX AS DistanceGroup,
COUNT(*) AS PointCount
FROM YourTable
GROUP BY ROUND(PointColumn.STDistance(@referencePoint) / @referencePoint.STX, 0) * @referencePoint.STX
ORDER BY DistanceGroup;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn1.STDistance(PointColumn2) AS Distance,
PointColumn1.STDistance(@referencePoint) - LAG(PointColumn1.STDistance(PointColumn2)) OVER (ORDER BY ID) AS DistanceDifference 
FROM YourTable2 ORDER BY PointColumn1.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STDistance(@referencePoint) AS Distance,
@referencePoint.STDistance(PointColumn) - LAG(@referencePoint.STX) OVER (ORDER BY ID) AS DistanceDifference
FROM YourTable ORDER BY PointColumn.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @maxDistance float = 3.0;
EXEC GetPointsWithinDistance @referencePoint, @maxDistance;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @maxDistance float = 3.0;
DECLARE @DynamicQuery NVARCHAR(MAX);
SET @DynamicQuery = N'
SELECT * FROM YourTable
WHERE PointColumn.STDistance(geometry::STGeomFromText(' + QUOTENAME(@referencePoint.STAsText(), '''') + ', 4326)) <= ' + CAST(@maxDistance AS NVARCHAR(MAX)) + ' ORDER BY PointColumn.STX';
EXEC sp_executesql @DynamicQuery;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @DynamicQuery NVARCHAR(MAX);
SET @DynamicQuery = N'
SELECT * FROM YourTable
WHERE PointColumn.STDistance(geometry::STGeomFromText(' + QUOTENAME(@referencePoint.STAsText(), '''') + ', 4326)) <= ' + CAST(@referencePoint.STX AS NVARCHAR(MAX)) + ' ORDER BY PointColumn.STX';
EXEC sp_executesql @DynamicQuery;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @thresholdDistance float = 3.0;
SELECT ID, PointColumn.STDistance(@referencePoint) AS DistanceToReferencePoint,
CASE WHEN PointColumn.STDistance(@referencePoint) <= @thresholdDistance THEN 'Close'
ELSE 'Far'
END AS Proximity
FROM YourTable ORDER BY PointColumn.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, @referencePoint.STDistance(PointColumn) AS DistanceToReferencePoint,
CASE WHEN @referencePoint.STDistance(PointColumn) <= @referencePoint.STY THEN 'Close'
ELSE 'Far'
END AS Proximity
FROM YourTable ORDER BY PointColumn.STX;
GO

DECLARE @distanceRanges TABLE (MinDistance float, MaxDistance float);
INSERT INTO @distanceRanges VALUES (0, 5), (5, 10), (10, 15);
SELECT * FROM ( SELECT ID,
CASE WHEN PointColumn1.STDistance(PointColumn2) BETWEEN 0 AND 5 THEN '0-5'
WHEN PointColumn1.STDistance(PointColumn2) BETWEEN 5.1 AND 10 THEN '5.1-10'
WHEN PointColumn1.STDistance(PointColumn2) BETWEEN 10.1 AND 15 THEN '10.1-15'
ELSE '15.1+'
END AS DistanceRange
FROM YourTable2 ORDER BY PointColumn1.STX
) AS Source
PIVOT ( COUNT(ID) FOR DistanceRange IN ([0-5], [5.1-10], [10.1-15], [15.1+])) AS PivotTable;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, PointColumn.STDistance(@referencePoint) AS Distance,
JSON_QUERY('{"Distance":' + CAST(PointColumn.STDistance(@referencePoint) AS NVARCHAR(MAX)) + '}') AS DistanceJson
FROM YourTable ORDER BY PointColumn.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT ID, @referencePoint.STDistance(PointColumn) AS Distance,
JSON_QUERY('{"Distance":' + CAST(@referencePoint.STDistance(PointColumn) AS NVARCHAR(MAX)) + '}') AS DistanceJson
FROM YourTable ORDER BY PointColumn.STX;
GO

SELECT [PointColumn1].STDistance([PointColumn2]) AS distance FROM [YourTable2] ORDER BY PointColumn1.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
DECLARE @thresholdDistance float = 10.0;
DECLARE @sql NVARCHAR(MAX);
DECLARE @params NVARCHAR(MAX);
SET @sql = N'
SELECT ID, PointColumn.STDistance(@referencePoint) AS DistanceToReferencePoint,
CASE WHEN PointColumn.STDistance(@referencePoint) <= @thresholdDistance THEN ''Close''
ELSE ''Far''
END AS Proximity
FROM YourTable
WHERE PointColumn.STDistance(@referencePoint) <= @thresholdDistance ORDER BY PointColumn.STX;';
SET @params = N'@referencePoint geometry, @thresholdDistance float';
EXEC sp_executesql @sql, @params, @referencePoint, @thresholdDistance;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT PointColumn.STDistance(@referencePoint) AS Distance FROM YourTable ORDER BY PointColumn.STX;
SELECT YourTable.PointColumn.STDistance(@referencePoint) AS Distance FROM YourTable ORDER BY PointColumn.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326);
SELECT dbo.YourTable.PointColumn.STDistance(@referencePoint) AS Distance FROM YourTable ORDER BY PointColumn.STX;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326); 
UPDATE YourTable SET PointColumn = @referencePoint
WHERE PointColumn.STDistance(@referencePoint) <= 2.0;
GO

DECLARE @referencePoint geometry = geometry::Point(0.0, 0.0, 4326); 
UPDATE YourTable SET PointColumn = @referencePoint
WHERE @referencePoint.STDistance(PointColumn) <= 2.0;
GO

-- Create Type Test Case currently Babelfish supports it but TSQL doesn't for spatial Types, Although it doesn't break anything
-- TODO: Make it similar to T-SQL
SELECT * FROM TypeTable ORDER BY ID;
GO

SELECT * FROM GeomToVarbinary ORDER BY p;
GO
SELECT * FROM GeomTochar ORDER BY p;
GO
SELECT * FROM GeomToVarchar ORDER BY p;
GO
SELECT * FROM TypeToGeom ORDER BY p.STX;
GO

-- Testing Explicit CASTs to and from Geometry data type
-- Supported CASTs to and from Geometry data type
Select CAST(CAST (0xE6100000010C17D9CEF753D34740D34D6210585936C0 AS binary) as geometry)
GO
Select CAST(CAST (0xE6100000010C17D9CEF753D34740D34D6210585936C0 AS varbinary(MAX)) as geometry)
GO
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS varbinary(MAX))
GO
Select CAST(CAST ('POINT(1 2)' AS char) as geometry)
GO
Select CAST(CAST ('POINT(200 2)' AS char) as geometry).STY
GO
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS char)
GO
Select CAST(CAST ('POINT(1 2)' AS nchar) as geometry)
GO
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS nchar)
GO
Select CAST(CAST ('POINT(1 2)' AS varchar) as geometry)
GO
Select CAST(CAST ('POINT(200 2)' AS varchar) as geometry).STY
GO
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS varchar)
GO
Select CAST(CAST ('POINT(1 2)' AS nvarchar) as geometry)
GO
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS nvarchar)
GO
Select CAST (geometry::STGeomFromText('Point(47.65100 -22.34900)', 0) AS varbinary)
GO
Select CAST (geometry::STGeomFromText('Point(47.65100 -22.34900)', 0) AS bytea)
GO
Select CAST (geometry::STGeomFromText('Point(47.65100 -22.34900)', 4326) AS varbinary)
GO
Select CAST (geometry::STGeomFromText('Point(47.65100 -22.34900)', 4326) AS bytea)
GO
Select CAST(CAST (geometry::STGeomFromText('Point(47.65100 -22.34900)', 0) AS varbinary) AS geometry)
GO
Select CAST(CAST (geometry::STGeomFromText('Point(47.65100 -22.34900)', 0) AS bytea) AS geometry)
GO
Select CAST(CAST (geometry::STGeomFromText('Point(47.65100 -22.34900)', 4326) AS varbinary) AS geometry)
GO
Select CAST(CAST (geometry::STGeomFromText('Point(47.65100 -22.34900)', 4326) AS bytea) AS geometry)
GO
Select Convert(bytea, geometry::STGeomFromText('Point(47.65100 -22.34900)', 0))
GO
Select Convert(varbinary, geometry::STGeomFromText('Point(47.65100 -22.34900)', 0))
GO
Select Convert(bytea, geometry::STGeomFromText('Point(47.65100 -22.34900)', 999999))
GO
Select Convert(varbinary, geometry::STGeomFromText('Point(47.65100 -22.34900)', 999999))
GO
Select Convert(bytea, geometry::STGeomFromText('Point(47.65100 -22.34900)', 4326))
GO
Select Convert(varbinary, geometry::STGeomFromText('Point(47.65100 -22.34900)', 4326))
GO
Select Convert(geometry, Convert(bytea, geometry::STGeomFromText('Point(47.65100 -22.34900)', 0)))
GO
Select Convert(geometry, Convert(varbinary, geometry::STGeomFromText('Point(47.65100 -22.34900)', 0)))
GO
Select Convert(geometry, Convert(bytea, geometry::STGeomFromText('Point(47.65100 -22.34900)', 999999)))
GO
Select Convert(geometry, Convert(varbinary, geometry::STGeomFromText('Point(47.65100 -22.34900)', 999999)))
GO
Select Convert(geometry, Convert(bytea, geometry::STGeomFromText('Point(47.65100 -22.34900)', 4326)))
GO
Select Convert(geometry, Convert(varbinary, geometry::STGeomFromText('Point(47.65100 -22.34900)', 4326)))
GO

-- UnSupported CASTs to and from Geometry data type
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS datetime)
GO
Select CAST(CAST (0001-01-01 AS datetime) as geometry)
GO
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS decimal)
GO
Select CAST(CAST (20.0 AS decimal) as geometry)
GO
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS bigInt)
GO
Select CAST(CAST (20 AS bigInt) as geometry)
GO
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS bigInt)
GO
Select CAST(CAST (20 AS bigInt) as geometry)
GO
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS money)
GO
Select CAST(CAST ($1 AS money) as geometry)
GO
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS bit)
GO
Select CAST(CAST (1 AS bit) as geometry)
GO
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS uniqueidentifier)
GO
Select CAST(CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS uniqueidentifier) as geometry)
GO
Select CAST(CAST ('POINT(1 2)' AS text) as geometry)
GO
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS text)
GO
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS sql_variant)
GO
Select CAST(CAST ('POINT(1 2)' AS sql_variant) as geometry)
GO
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS xml)
GO
Select CAST(CAST ('<head>point(1 2)</head>' AS xml) as geometry)
GO
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS geography)
GO
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS geometry)
GO

-- UnSupported CASTs which are currently supported for geometry
-- This is because Image type is created as -> CREATE DOMAIN sys.IMAGE AS sys.BBF_VARBINARY; so it is always converted to it's baseType i.e. varbinary
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS image)
GO
Select CAST(CAST (0xE6100000010C17D9CEF753D34740D34D6210585936C0 AS image) as geometry)
GO

DECLARE @point geography;
SET @point = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STAsText(@point);
SELECT @point.STAsText();
Go

DECLARE @point geography;
SET @point = geography::Point(22.34900, -47.65100, 4326);
SELECT STAsText(@point);
SELECT @point.STAsText();
Go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT Long(@point);
SELECT Lat(@point);
SELECT @point.Long;
SELECT @point.Lat;
Go

DECLARE @point geography;
SET @point = geography::Point(22.34900, -47.65100, 4326);
SELECT Long(@point);
SELECT Lat(@point);
SELECT @point.Long;
SELECT @point.Lat;
Go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.35000 47.65000)', 4326);
SELECT STDistance(@point1, @point2);
SELECT @point1.STDistance(@point2);
Go

DECLARE @point geography;
SET @point = geography::STGeomFromText('POINT(-22.34900 47.65100)', 4326);
Insert INTO SPATIALPOINTGEOG_dt(location) VALUES(geography::point(@point.Long, @point.Lat, 4326))
go

DECLARE @Lat geography;
SET @Lat = geography::STGeomFromText('POINT(-22.34900 47.65100)', 4326);
select geography::Point(@Lat.Long, @Lat.Lat, 4326).Long, geography::Point(@Lat.Long, @Lat.Lat, 4326).Lat;
go

DECLARE @Lat geography;
SET @Lat = geography::STGeomFromText('POINT(-22.34900 47.65100)', 4326);
select geography::Point(@Lat.Long, @Lat.Lat, 4326).STAsText(), geography::Point(@Lat.Long, @Lat.Lat, 4326).STAsBinary(), geography::Point(@Lat.Long, @Lat.Lat, 4326).STDistance(geography::Point(@Lat.Long, @Lat.Lat, 4326));
go

SELECT
    SpatialData.ID,
    SPATIALPOINTGEOG_dt.location.Lat,
    SpatialLocation.STDistance(SPATIALPOINTGEOG_dt.location)
FROM
    SpatialData
JOIN
    SPATIALPOINTGEOG_dt ON SPATIALPOINTGEOG_dt.location.Long - SpatialData.SpatialLocation.Lat <= 10
ORDER BY location.Lat;
GO

WITH RegionLocations AS (
    SELECT
        SpatialData.ID,
        SPATIALPOINTGEOG_dt.location.Lat
    FROM
        SpatialData
    JOIN
        SPATIALPOINTGEOG_dt ON SPATIALPOINTGEOG_dt.location.Long - SpatialData.SpatialLocation.Lat <= 10
    ORDER BY location.Lat
)
SELECT
    Lat,
    COUNT(ID) AS LocationCount
FROM
    RegionLocations
GROUP BY
    Lat
Order BY Lat;
GO

-- Test with CTE
with mycte (a)
as (select SPATIALPOINTGEOG_dt.location from SPATIALPOINTGEOG_dt Order BY location.Lat)
select a.STAsText()
				from mycte x inner join SPATIALPOINTGEOG_dt y on x.a.Lat >= y.location.Long ORDER BY x.a.Lat;
go

-- Test with tvf
select f.STAsText()
                from testspatial_tvf(1) f inner join SPATIALPOINTGEOG_dt t on f.location.Lat >= t.location.Long ORDER BY f.location.Lat;
go

-- Null test for Geospatial functions
DECLARE @point1 geography, @point2 geography, @point3 geography;
SET @point1 = geography::STPointFromText(null, 4326);
SET @point2 = geography::STGeomFromText(null, 4326);
SET @point3 = geography::Point(22.34900, -47.65100, 4326);
SELECT @point1.Long;
SELECT @point1.Lat;
SELECT @point1.STAsText();
SELECT @point1.STAsBinary();
SELECT @point1.STDistance(@point2);
SELECT @point3.STDistance(@point2);
SELECT @point1.STDistance(@point3);
Go

-- Negative test for Geospatial functions
DECLARE @point1 geography, @point2 varchar(50), @point3 int;
SET @point1 = geography::Point(22.34900, -47.65100, 4326);
SET @point2 = 'Test_String';
SELECT @point2.STDistance(@point1);
Go

SELECT location.STY from SPATIALPOINTGEOG_dt ORDER BY location.Lat;
GO

SELECT * FROM GeogView ORDER BY Coordinates;
GO

select * from geoginTable ORDER BY a.Lat;
GO

SELECT * FROM SubqueryView ORDER BY Latitude;
GO

SELECT * FROM BrackExprView ORDER BY Latitude;
GO

SELECT * FROM FuncExprView ORDER BY Latitude;
GO

EXEC dbo.proc_getdata;
GO

geoginTest 'POINT(1 2)'
GO

geoginTest 'POINT(1 200)'
GO

geoginTest 'POINT(1000 20)'
GO

SELECT * FROM TextFromGeog ORDER BY Latitude;
GO

SELECT * FROM BinaryFromGeog ORDER BY BinaryRepresentation;
GO

SELECT * FROM CoordsFromGeog ORDER BY Coordinates;
GO

SELECT * FROM TransformFromGeog ORDER BY Modified_points.Lat;
GO

SELECT * FROM equal_geog ORDER BY point.Lat;
GO

SELECT * FROM point_distances_geog ORDER BY distance;
GO

SELECT location.Lat from SPATIALPOINTGEOG_dt ORDER BY location.Lat;
GO

SELECT SPATIALPOINTGEOG_dt.location.Long from SPATIALPOINTGEOG_dt ORDER BY location.Lat;
GO

SELECT location.STAsText() from SPATIALPOINTGEOG_dt ORDER BY location.Lat;
GO

SELECT location.STAsBinary() from SPATIALPOINTGEOG_dt ORDER BY location.Lat;
GO

SELECT location.STDistance(location) from SPATIALPOINTGEOG_dt ORDER BY location.Lat;
GO

SELECT [SPATIALPOINTGEOG_dt].[location].[Long] from [SPATIALPOINTGEOG_dt] ORDER BY location.Lat;
GO

SELECT [location].[Lat] from [SPATIALPOINTGEOG_dt] ORDER BY location.Lat;
GO

SELECT location FROM SPATIALPOINTGEOG_dt ORDER BY location.Lat;
GO

SELECT * FROM GeogToVarbinary ORDER BY p;
GO
SELECT * FROM GeogTochar ORDER BY p;
GO
SELECT * FROM GeogToVarchar ORDER BY p;
GO
SELECT * FROM TypeToGeog ORDER BY p.Lat;
GO

-- Testing Explicit CASTs to and from Geography data type
-- Supported CASTs to and from Geography data type
Select CAST(CAST (0xE6100000010C17D9CEF753D34740D34D6210585936C0 AS binary) as geography)
GO
Select CAST(CAST (0xE6100000010C17D9CEF753D34740D34D6210585936C0 AS varbinary(MAX)) as geography)
GO
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS varbinary(MAX))
GO
Select CAST(CAST ('POINT(1 2)' AS char) as geography)
GO
Select CAST(CAST ('POINT(200 2)' AS char) as geography).Long
GO
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS char)
GO
Select CAST(CAST ('POINT(1 2)' AS nchar) as geography)
GO
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS nchar)
GO
Select CAST(CAST ('POINT(1 2)' AS varchar) as geography)
GO
Select CAST(CAST ('POINT(200 2)' AS varchar) as geography).Long
GO
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS varchar)
GO
Select CAST(CAST ('POINT(1 2)' AS nvarchar) as geography)
GO
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS nvarchar)
GO
Select Convert(bytea, geography::STGeomFromText('Point(47.65100 -22.34900)', 0))
GO
Select Convert(varbinary, geography::STGeomFromText('Point(47.65100 -22.34900)', 0))
GO
Select Convert(bytea, geography::STGeomFromText('Point(47.65100 -22.34900)', 999999))
GO
Select Convert(varbinary, geography::STGeomFromText('Point(47.65100 -22.34900)', 999999))
GO
Select Convert(bytea, geography::STGeomFromText('Point(47.65100 -22.34900)', 4326))
GO
Select Convert(varbinary, geography::STGeomFromText('Point(47.65100 -22.34900)', 4326))
GO
Select Convert(geography, Convert(bytea, geography::STGeomFromText('Point(47.65100 -22.34900)', 0)))
GO
Select Convert(geography, Convert(varbinary, geography::STGeomFromText('Point(47.65100 -22.34900)', 0)))
GO
Select Convert(geography, Convert(bytea, geography::STGeomFromText('Point(47.65100 -22.34900)', 999999)))
GO
Select Convert(geography, Convert(varbinary, geography::STGeomFromText('Point(47.65100 -22.34900)', 999999)))
GO
Select Convert(geography, Convert(bytea, geography::STGeomFromText('Point(47.65100 -22.34900)', 4326)))
GO
Select Convert(geography, Convert(varbinary, geography::STGeomFromText('Point(47.65100 -22.34900)', 4326)))
GO

-- UnSupported CASTs to and from Geography data type
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS datetime)
GO
Select CAST(CAST (0001-01-01 AS datetime) as geography)
GO
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS decimal)
GO
Select CAST(CAST (20.0 AS decimal) as geography)
GO
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS bigInt)
GO
Select CAST(CAST (20 AS bigInt) as geography)
GO
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS bigInt)
GO
Select CAST(CAST (20 AS bigInt) as geography)
GO
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS money)
GO
Select CAST(CAST ($1 AS money) as geography)
GO
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS bit)
GO
Select CAST(CAST (1 AS bit) as geography)
GO
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS uniqueidentifier)
GO
Select CAST(CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS uniqueidentifier) as geography)
GO
Select CAST(CAST ('POINT(1 2)' AS text) as geography)
GO
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS text)
GO
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS sql_variant)
GO
Select CAST(CAST ('POINT(1 2)' AS sql_variant) as geography)
GO
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS xml)
GO
Select CAST(CAST ('<head>point(1 2)</head>' AS xml) as geography)
GO

-- UnSupported CASTs which are currently supported for geography
-- This is because Image type is created as -> CREATE DOMAIN sys.IMAGE AS sys.BBF_VARBINARY; so it is always converted to it's baseType i.e. varbinary
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS image)
GO
Select CAST(CAST (0xE6100000010C17D9CEF753D34740D34D6210585936C0 AS image) as geography)
GO

SELECT
    GeomColumn.STX AS XCoordinate,
    GeomColumn.STY AS YCoordinate,
    PrimaryKey,
    GeogColumn.STDistance(geography::Point(7, 8, 4326)) AS DistanceToFixedPoint
FROM
    SPATIALPOINT_dt ORDER BY GeomColumn.STX;
GO

DECLARE @sql NVARCHAR(MAX);
SET @sql = 
    N'SELECT ' +
    N'GeomColumn.STX AS XCoordinate, ' +
    N'GeomColumn.STY AS YCoordinate, ' +
    N'PrimaryKey, ' +
    N'GeogColumn.STDistance(geography::Point(7, 8, 4326)) AS DistanceToFixedPoint ' +
    N'FROM SPATIALPOINT_dt ORDER BY GeomColumn.STX';

-- Execute the dynamic SQL
EXEC sp_executesql @sql;
GO

SELECT * FROM SPATIALPOINT_dt ORDER BY GeomColumn.STX;
GO

SELECT * FROM geomTabWithoutSrid ORDER BY PrimaryKey;
GO
SELECT CAST(GeomColumn as bytea), CAST(GeomColumn as varbinary) FROM geomTabWithoutSrid ORDER BY GeomColumn.STX;
GO
SELECT PrimaryKey, CAST(ByteaColumn as geometry), CAST(ByteaColumn as varbinary) FROM geomTabWithoutSrid ORDER BY PrimaryKey;
GO
SELECT Convert(geometry, Convert(bytea, GeomColumn)), Convert(geometry, Convert(varbinary, GeomColumn)) FROM geomTabWithoutSrid ORDER BY GeomColumn.STX;
GO
SELECT Convert(bytea, GeomColumn), Convert(varbinary, GeomColumn) FROM geomTabWithoutSrid ORDER BY GeomColumn.STX;
GO
SELECT Convert(varbinary, Convert(geometry, ByteaColumn)), Convert(geometry, Convert(varbinary, ByteaColumn)) FROM geomTabWithoutSrid ORDER BY PrimaryKey;
GO
SELECT Convert(geometry, ByteaColumn), Convert(varbinary, ByteaColumn) FROM geomTabWithoutSrid ORDER BY PrimaryKey;
GO

-- Here we are testing ambiguity scenario for func_ref functions but we prioritize Geospatial Call in this case (Needs Documentation)
SELECT geom_schema.STDistance(geom_schema) from geometry_test ORDER BY geom_schema.STX
GO

-- Here we are testing ambiguity scenario for col_ref functions but we prioritize Geospatial Call in this case (Needs Documentation)
SELECT STX.STX from STX ORDER BY STX.STX
GO

INSERT INTO babelfish_migration_mode_table SELECT current_setting('babelfishpg_tsql.migration_mode')
GO

-- test multi-db mode
SELECT set_config('role', 'jdbc_user', false);
GO

CREATE DATABASE db1;
GO

CREATE DATABASE db2;
GO

USE db1;
GO

CREATE TABLE SpatialData
(
    SpatialPoint GEOMETRY,
    PrimaryKey INT
);
GO

INSERT INTO SpatialData (SpatialPoint, PrimaryKey)
VALUES
    (geometry::Point(1, 2, 0), 1),
    (geometry::Point(3, 4, 0), 2),
    (geometry::Point(5, 6, 0), 3);
GO

USE db2;
GO

CREATE TABLE SpatialData
(
    SpatialPoint GEOMETRY,
    PrimaryKey INT
);
GO

INSERT INTO SpatialData (SpatialPoint, PrimaryKey)
VALUES
    (geometry::Point(7, 8, 0), 4),
    (geometry::Point(9, 10, 0), 5),
    (geometry::Point(11, 12, 0), 6);
GO

DECLARE @sql NVARCHAR(MAX);
SET @sql = 
    N'SELECT ' +
    N'[SpatialPoint].[STX] AS XCoordinate, ' +
    N'[SpatialPoint].[STY] AS YCoordinate, ' +
    N'[PrimaryKey] ' +
    N'FROM [db1].[dbo].[SpatialData] ' +
    N'UNION ALL ' +
    N'SELECT ' +
    N'[SpatialPoint].[STX] AS XCoordinate, ' +
    N'[SpatialPoint].[STY] AS YCoordinate, ' +
    N'[PrimaryKey] ' +
    N'FROM [db2].[dbo].[SpatialData] ORDER BY SpatialPoint.STX';
-- Execute the dynamic SQL
EXEC sp_executesql @sql;
GO

USE master
GO

DROP DATABASE db1;
GO

DROP DATABASE db2;
GO

-- Tests for db level collation
CREATE DATABASE db1 COLLATE BBF_Unicode_CP1_CI_AI;
GO

CREATE DATABASE db2 COLLATE BBF_Unicode_CP1_CI_AI;
GO

USE db1;
GO

CREATE TABLE SpatialData
(
    SpatialPoint GEOMETRY,
    PrimaryKey INT
);
GO

INSERT INTO SpatialData (SpatialPoint, PrimaryKey)
VALUES
    (geometry::Point(1, 2, 0), 1),
    (geometry::Point(3, 4, 0), 2),
    (geometry::Point(5, 6, 0), 3);
GO

USE db2;
GO

CREATE TABLE SpatialData
(
    SpatialPoint GEOMETRY,
    PrimaryKey INT
);
GO

INSERT INTO SpatialData (SpatialPoint, PrimaryKey)
VALUES
    (geometry::Point(7, 8, 0), 4),
    (geometry::Point(9, 10, 0), 5),
    (geometry::Point(11, 12, 0), 6);
GO

DECLARE @sql NVARCHAR(MAX);
SET @sql = 
    N'SELECT ' +
    N'[SpatialPoint].[STX] AS XCoordinate, ' +
    N'[SpatialPoint].[STY] AS YCoordinate, ' +
    N'[PrimaryKey] ' +
    N'FROM [db1].[dbo].[SpatialData] ' +
    N'UNION ALL ' +
    N'SELECT ' +
    N'[SpatialPoint].[STX] AS XCoordinate, ' +
    N'[SpatialPoint].[STY] AS YCoordinate, ' +
    N'[PrimaryKey] ' +
    N'FROM [db2].[dbo].[SpatialData] ORDER BY SpatialPoint.STX';
-- Execute the dynamic SQL
EXEC sp_executesql @sql;
GO

USE master
GO

DROP DATABASE db1;
GO

DROP DATABASE db2;
GO

SELECT set_config('role', 'jdbc_user', false);
GO

-- Reset migration mode to default
DECLARE @mig_mode VARCHAR(10)
SET @mig_mode = (SELECT mig_mode FROM babelfish_migration_mode_table WHERE id_num = 1)
SELECT CASE WHEN (SELECT set_config('babelfishpg_tsql.migration_mode', @mig_mode, false)) IS NOT NULL THEN 1 ELSE 0 END
GO

SELECT name, object_name(t.system_type_id), principal_id, max_length, precision, scale , collation_name, is_nullable, is_user_defined, is_assembly_type, default_object_id, rule_object_id, is_table_type from sys.types t WHERE name = 'geometry' ORDER BY name
go

SELECT name, object_name(t.system_type_id), principal_id, max_length, precision, scale , collation_name, is_nullable, is_user_defined, is_assembly_type, default_object_id, rule_object_id, is_table_type from sys.types t WHERE name = 'geography' ORDER BY name
go

exec sp_sproc_columns_100 @procedure_name= 'geometry_proc_1'
GO

exec sp_sproc_columns_100 @procedure_name= 'geography_proc_1'
GO

select * from information_schema.columns where table_name = 'geo_view_test' ORDER BY column_name
GO

select name , column_id , max_length , precision , scale , collation_name ,is_nullable , is_ansi_padded , is_rowguidcol , is_identity ,is_computed , is_filestream , is_replicated , is_non_sql_subscribed , is_merge_published , is_dts_replicated , is_xml_document , xml_collection_id , default_object_id , rule_object_id , is_sparse , is_column_set , generated_always_type , generated_always_type_desc , encryption_type , encryption_type_desc , encryption_algorithm_name , column_encryption_key_id , column_encryption_key_database_name , is_hidden , is_masked , graph_type , graph_type_desc from sys.columns where object_id = object_id('geo_view_test') ORDER BY name;
GO

SELECT name, principal_id, max_length, precision, scale, collation_name, is_nullable, is_user_defined, is_assembly_type, default_object_id, rule_object_id, assembly_id, assembly_class, is_binary_ordered, is_fixed_length, prog_id, assembly_qualified_name, is_table_type FROM sys.assembly_types
WHERE user_type_id = TYPE_ID('dbo.GeospatialUDT')
ORDER BY name DESC
GO
