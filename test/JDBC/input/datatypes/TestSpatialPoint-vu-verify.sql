DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STAsText(@point);
SELECT @point.STAsText();
Go

DECLARE @point geometry;
SET @point = geometry::POINT(22.34900, -47.65100, 4326);
SELECT STAsText(@point);
SELECT @point.STAsText();
Go

DECLARE @point geometry;
SET @point = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT stx(@point);
SELECT sty(@point);
SELECT @point.stx;
SELECT @point.sty;
Go

DECLARE @point geometry;
SET @point = geometry::POINT(22.34900, -47.65100, 4326);
SELECT stx(@point);
SELECT sty(@point);
SELECT @point.stx;
SELECT @point.sty;
Go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geometry::STGeomFromText('POINT(-122.35000 47.65000)', 4326);
SELECT STDistance(@point1, @point2);
SELECT @point1.STDistance(@point2);
Go

DECLARE @point geometry;
SET @point = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
Insert INTO SPATIALPOINTGEOM_dt(location) VALUES(geometry::point(@point.STX, @point.STY,4326))
go

-- Currently it is not supported
-- TODO: Need to support it and make it similar to TSQL
DECLARE @STX geometry;
SET @STX = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
select geometry::Point(@STX.STX, @STX.STY, 4326).STX, geometry::Point(@STX.STX, @STX.STY, 4326).STY;
go

-- Currently it is not supported
-- TODO: Need to support it and make it similar to TSQL
DECLARE @STX geometry;
SET @STX = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
select geometry::Point(@STX.STX, @STX.STY, 4326).STAsText(), geometry::Point(@STX.STX, @STX.STY, 4326).STAsBinary(), geometry::Point(@STX.STX, @STX.STY, 4326).STDistance(geometry::Point(@STX.STX, @STX.STY, 4326));
go

-- Null test for Geospatial functions
DECLARE @point1 geometry, @point2 geometry, @point3 geometry;
SET @point1 = geometry::STPointFromText(null, 4326);
SET @point2 = geometry::STGeomFromText(null, 4326);
SET @point3 = geometry::POINT(22.34900, -47.65100, 4326);
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
SET @point1 = geometry::POINT(22.34900, -47.65100, 4326);;
SET @point2 = 'Test_String';
SELECT @point1.STDistance(@point2);
Go

SELECT location.LAT from SPATIALPOINTGEOM_dt;
GO

SELECT * FROM GeomView;
GO

SELECT * FROM ValFromGeom;
GO

EXEC dbo.p_getcoordinates;
GO

SELECT * FROM TextFromGeom;
GO

SELECT * FROM BinaryFromGeom;
GO

SELECT * FROM CoordsFromGeom;
GO

SELECT * FROM equal_geom;
GO

SELECT * FROM point_distances_geom;
GO

SELECT location.STX from SPATIALPOINTGEOM_dt;
GO

SELECT SPATIALPOINTGEOM_dt.location.STY from SPATIALPOINTGEOM_dt;
GO

SELECT location.STAsText() from SPATIALPOINTGEOM_dt;
GO

SELECT location.STAsBinary() from SPATIALPOINTGEOM_dt;
GO

SELECT location.STDistance(geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326)) from SPATIALPOINTGEOM_dt;
GO

SELECT [SPATIALPOINTGEOM_dt].[location].[STX] from [SPATIALPOINTGEOM_dt];
GO

SELECT [location].[STY] from [SPATIALPOINTGEOM_dt];
GO

SELECT location FROM SPATIALPOINTGEOM_dt; 
GO

-- Create Type Test Case currently Babelfish supports it but TSQL doesn't for spatial Types, Although it doesn't break anything
-- TODO: Make it similar to T-SQL
SELECT * FROM TypeTable;
GO

SELECT * FROM GeomToVarbinary;
GO
SELECT * FROM GeomTochar;
GO
SELECT * FROM GeomToVarchar;
GO
SELECT * FROM TypeToGeom;
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
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS char)
GO
Select CAST(CAST ('POINT(1 2)' AS nchar) as geometry)
GO
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS nchar)
GO
Select CAST(CAST ('POINT(1 2)' AS varchar) as geometry)
GO
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS varchar)
GO
Select CAST(CAST ('POINT(1 2)' AS nvarchar) as geometry)
GO
Select CAST (geometry::STGeomFromText('POINT(1.0 2.0)', 4326) AS nvarchar)
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
SET @point = geography::POINT(22.34900, -47.65100, 4326);
SELECT STAsText(@point);
SELECT @point.STAsText();
Go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT long(@point);
SELECT lat(@point);
SELECT @point.long;
SELECT @point.lat;
Go

DECLARE @point geography;
SET @point = geography::POINT(22.34900, -47.65100, 4326);
SELECT long(@point);
SELECT lat(@point);
SELECT @point.long;
SELECT @point.lat;
Go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.35000 47.65000)', 4326);
SELECT STDistance(@point1, @point2);
SELECT @point1.STDistance(@point2);
Go

DECLARE @point geography;
SET @point = geography::STGeomFromText('POINT(-22.34900 47.65100)', 4326);
Insert INTO SPATIALPOINTGEOG_dt(location) VALUES(geography::point(@point.LONG, @point.LAT, 4326))
go

-- Currently it is not supported
-- TODO: Need to support it and make it similar to TSQL
DECLARE @LAT geography;
SET @LAT = geography::STGeomFromText('POINT(-22.34900 47.65100)', 4326);
select geography::Point(@LAT.LONG, @LAT.LAT, 4326).LONG, geography::Point(@LAT.LONG, @LAT.LAT, 4326).LAT;
go

-- Currently it is not supported
-- TODO: Need to support it and make it similar to TSQL
DECLARE @LAT geography;
SET @LAT = geography::STGeomFromText('POINT(-22.34900 47.65100)', 4326);
select geography::Point(@LAT.LONG, @LAT.LAT, 4326).STAsText(), geography::Point(@LAT.LONG, @LAT.LAT, 4326).STAsBinary(), geography::Point(@LAT.LONG, @LAT.LAT, 4326).STDistance(geography::Point(@LAT.LONG, @LAT.LAT, 4326));
go

SELECT
    SpatialData.ID,
    SPATIALPOINTGEOG_dt.location.LAT,
    SpatialLocation.STDistance(SPATIALPOINTGEOG_dt.location)
FROM
    SpatialData
JOIN
    SPATIALPOINTGEOG_dt ON SPATIALPOINTGEOG_dt.location.long - SpatialData.SpatialLocation.lat <= 10;
GO

WITH RegionLocations AS (
    SELECT
        SpatialData.ID,
        SPATIALPOINTGEOG_dt.location.LAT
    FROM
        SpatialData
    JOIN
        SPATIALPOINTGEOG_dt ON SPATIALPOINTGEOG_dt.location.long - SpatialData.SpatialLocation.lat <= 10
)
SELECT
    lat,
    COUNT(ID) AS LocationCount
FROM
    RegionLocations
GROUP BY
    lat;
GO

-- Test with CTE
with mycte (a)
as (select SPATIALPOINTGEOG_dt.location from SPATIALPOINTGEOG_dt)
select a.STAsText()
				from mycte x inner join SPATIALPOINTGEOG_dt y on x.a.lat >= y.location.long;
go

-- Test with tvf
select f.STAsText()
                from testspatial_tvf(1) f inner join SPATIALPOINTGEOG_dt t on f.location.lat >= t.location.long;
go

-- Null test for Geospatial functions
DECLARE @point1 geography, @point2 geography, @point3 geography;
SET @point1 = geography::STPointFromText(null, 4326);
SET @point2 = geography::STGeomFromText(null, 4326);
SET @point3 = geography::POINT(22.34900, -47.65100, 4326);
SELECT @point1.LONG;
SELECT @point1.LAT;
SELECT @point1.STAsText();
SELECT @point1.STAsBinary();
SELECT @point1.STDistance(@point2);
SELECT @point3.STDistance(@point2);
SELECT @point1.STDistance(@point3);
Go

-- Negative test for Geospatial functions
DECLARE @point1 geography, @point2 varchar(50), @point3 int;
SET @point1 = geography::POINT(22.34900, -47.65100, 4326);
SET @point2 = 'Test_String';
SELECT @point2.STDistance(@point1);
Go

SELECT location.STY from SPATIALPOINTGEOG_dt;
GO

SELECT * FROM GeogView;
GO

EXEC dbo.proc_getdata;
GO

SELECT * FROM TextFromGeog;
GO

SELECT * FROM BinaryFromGeog;
GO

SELECT * FROM CoordsFromGeog;
GO

SELECT * FROM TransformFromGeog;
GO

SELECT * FROM equal_geog;
GO

SELECT * FROM point_distances_geog;
GO

SELECT location.LAT from SPATIALPOINTGEOG_dt;
GO

SELECT SPATIALPOINTGEOG_dt.location.LONG from SPATIALPOINTGEOG_dt;
GO

SELECT location.STAsText() from SPATIALPOINTGEOG_dt;
GO

SELECT location.STAsBinary() from SPATIALPOINTGEOG_dt;
GO

SELECT location.STDistance(geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326)) from SPATIALPOINTGEOG_dt;
GO

SELECT [SPATIALPOINTGEOG_dt].[location].[LONG] from [SPATIALPOINTGEOG_dt];
GO

SELECT [location].[LAT] from [SPATIALPOINTGEOG_dt];
GO

SELECT location FROM SPATIALPOINTGEOG_dt;
GO

SELECT * FROM GeogToVarbinary;
GO
SELECT * FROM GeogTochar;
GO
SELECT * FROM GeogToVarchar;
GO
SELECT * FROM TypeToGeog;
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
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS char)
GO
Select CAST(CAST ('POINT(1 2)' AS nchar) as geography)
GO
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS nchar)
GO
Select CAST(CAST ('POINT(1 2)' AS varchar) as geography)
GO
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS varchar)
GO
Select CAST(CAST ('POINT(1 2)' AS nvarchar) as geography)
GO
Select CAST (geography::STGeomFromText('POINT(1.0 2.0)', 4326) AS nvarchar)
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
    SPATIALPOINT_dt;
GO

DECLARE @sql NVARCHAR(MAX);
SET @sql = 
    N'SELECT ' +
    N'GeomColumn.STX AS XCoordinate, ' +
    N'GeomColumn.STY AS YCoordinate, ' +
    N'PrimaryKey, ' +
    N'GeogColumn.STDistance(geography::Point(7, 8, 4326)) AS DistanceToFixedPoint ' +
    N'FROM SPATIALPOINT_dt';
    
-- Execute the dynamic SQL
EXEC sp_executesql @sql;
GO

SELECT * FROM SPATIALPOINT_dt;
GO

INSERT INTO babelfish_migration_mode_table SELECT current_setting('babelfishpg_tsql.migration_mode')
GO

-- test multi-db mode
SELECT set_config('role', 'jdbc_user', false);
GO
SELECT set_config('babelfishpg_tsql.migration_mode', 'multi-db', false);
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
    N'FROM [db2].[dbo].[SpatialData]';
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
