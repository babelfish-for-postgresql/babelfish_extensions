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

SELECT location FROM SPATIALPOINTGEOM_dt; 
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

SELECT location FROM SPATIALPOINTGEOG_dt;
GO

SELECT * FROM SPATIALPOINT_dt;
GO
