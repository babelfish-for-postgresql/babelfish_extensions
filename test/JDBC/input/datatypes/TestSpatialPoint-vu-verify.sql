DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point.STAsText();
Go

DECLARE @point geometry;
SET @point = geometry::POINT(22.34900, -47.65100, 4326);
SELECT @point.STAsText();
Go

DECLARE @point geometry;
SET @point = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point.stx;
SELECT @point.sty;
Go

DECLARE @point geometry;
SET @point = geometry::POINT(22.34900, -47.65100, 4326);
SELECT @point.stx;
SELECT @point.sty;
Go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geometry::STGeomFromText('POINT(-122.35000 47.65000)', 4326);
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
select geometry::Point(@STX.STX, @STX.STY, 4326).STX
go

-- Currently it is not supported
-- TODO: Need to support it and make it similar to TSQL
CREATE VIEW CoordsFromGeom AS SELECT location.STX, location.STY AS Coordinates FROM SPATIALPOINTGEOM_dt;
GO

-- Currently it is not supported
-- TODO: Need to support it and make it similar to TSQL
DECLARE @STX geometry;
SET @STX = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
select geometry::Point(@STX.STX, @STX.STY, 4326).STAsText()
go

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

SELECT [location].[STX] from [SPATIALPOINTGEOM_dt];
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
SELECT @point.STAsText();
Go

DECLARE @point geography;
SET @point = geography::POINT(22.34900, -47.65100, 4326);
SELECT @point.STAsText();
Go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT @point.long;
SELECT @point.lat;
Go

DECLARE @point geography;
SET @point = geography::POINT(22.34900, -47.65100, 4326);
SELECT @point.long;
SELECT @point.lat;
Go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.35000 47.65000)', 4326);
SELECT @point1.STDistance(@point2);
Go

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
SELECT set_config('babelfishpg_tsql.migration_mode', 'single-db', false);
GO
