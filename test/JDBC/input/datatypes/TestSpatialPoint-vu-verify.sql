DECLARE @point geometry;
SET @point = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT STAsText(@point);
Go

DECLARE @point geometry;
SET @point = geometry::POINT(22.34900, -47.65100, 4326);
SELECT STAsText(@point);
Go

DECLARE @point geometry;
SET @point = geometry::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT stx(@point);
SELECT sty(@point);
Go

DECLARE @point geometry;
SET @point = geometry::POINT(22.34900, -47.65100, 4326);
SELECT stx(@point);
SELECT sty(@point);
Go

DECLARE @point1 geometry, @point2 geometry;
SET @point1 = geometry::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geometry::STGeomFromText('POINT(-122.35000 47.65000)', 4326);
SELECT STDistance(@point1, @point2);
Go

SELECT * FROM TextFromGeom;
GO

SELECT * FROM BinaryFromGeom;
GO

SELECT * FROM CoordsFromGeom;
GO

SELECT * FROM point_distances_geom;
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
Go

DECLARE @point geography;
SET @point = geography::POINT(22.34900, -47.65100, 4326);
SELECT STAsText(@point);
Go

DECLARE @point geography;
SET @point = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SELECT long(@point);
SELECT lat(@point);
Go

DECLARE @point geography;
SET @point = geography::POINT(22.34900, -47.65100, 4326);
SELECT long(@point);
SELECT lat(@point);
Go

DECLARE @point1 geography, @point2 geography;
SET @point1 = geography::STPointFromText('POINT(-122.34900 47.65100)', 4326);
SET @point2 = geography::STGeomFromText('POINT(-122.35000 47.65000)', 4326);
SELECT STDistance(@point1, @point2);
Go

SELECT * FROM TextFromGeog;
GO

SELECT * FROM BinaryFromGeog;
GO

SELECT * FROM CoordsFromGeog;
GO

SELECT * FROM TransformFromGeog;
GO

SELECT * FROM point_distances_geog;
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

SELECT * FROM SPATIALPOINT_dt;
GO
