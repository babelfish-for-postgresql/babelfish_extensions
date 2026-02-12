--MakeValid
DECLARE @g geometry;
SET @g = NULL;
SELECT @g.MakeValid() AS result;
go

DECLARE @g geometry;
SET @g = geometry::STGeomFromText('POINT EMPTY', 0);
SELECT @g.MakeValid().STAsText() AS result;
go

DECLARE @g geometry;
SET @g = geometry::STGeomFromText('POLYGON EMPTY', 0);
SELECT @g.MakeValid().STAsText() AS result;
go

DECLARE @g geometry;
SET @g = geometry::STGeomFromText('POINT(10 20)', 0);
SELECT @g.MakeValid().STAsText() AS result, @g.MakeValid().STIsValid() AS is_valid;
go

DECLARE @g geometry;
SET @g = geometry::STGeomFromText('POINT(10 20)', 4326);
SELECT @g.MakeValid().STAsText() AS result, @g.MakeValid().STSrid AS srid;
go

DECLARE @g geometry;
SET @g = geometry::STGeomFromText('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))', 0);
SELECT @g.MakeValid().STAsText() AS result, @g.MakeValid().STIsValid() AS is_valid;
go

DECLARE @g geometry;
SET @g = geometry::STGeomFromText('POLYGON((0 0, 10 10, 10 0, 0 10, 0 0))', 0);
SELECT @g.STIsValid() AS before_valid, @g.MakeValid().STIsValid() AS after_valid;
go

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

DECLARE @g geometry;
SET @g = geometry::STGeomFromText('POLYGON((0 0, 10 10, 10 0, 0 10, 0 0))', 0);
SELECT @g.MakeValid().MakeValid().STIsValid() AS is_valid;
go

DECLARE @g geography;
SET @g = NULL;
SELECT @g.MakeValid() AS result;
go

DECLARE @g geography;
SET @g = geography::STGeomFromText('POINT EMPTY', 4326);
SELECT @g.MakeValid().STAsText() AS result;
go

DECLARE @g geography;
SET @g = geography::STGeomFromText('POLYGON EMPTY', 4326);
SELECT @g.MakeValid().STAsText() AS result;
go

DECLARE @g geography;
SET @g = geography::STGeomFromText('POINT(-122.349 47.651)', 4326);
SELECT @g.MakeValid().STAsText() AS result, @g.MakeValid().STIsValid() AS is_valid;
go

DECLARE @g geography;
SET @g = geography::Point(47.651, -122.349, 4326);
SELECT @g.MakeValid().STAsText() AS result, @g.MakeValid().STIsValid() AS is_valid;
go

DECLARE @g geography;
SET @g = geography::STGeomFromText('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))', 4326);
SELECT @g.MakeValid().STAsText() AS result, @g.MakeValid().STIsValid() AS is_valid;
go

DECLARE @g geography;
SET @g = geography::STGeomFromText('POLYGON((0 0, 10 10, 10 0, 0 10, 0 0))', 4326);
SELECT @g.STIsValid() AS before_valid, @g.MakeValid().STIsValid() AS after_valid;
go

DECLARE @g geography;
SET @g = geography::STGeomFromText('POLYGON((0 0, 5 5, 10 0, 10 10, 5 5, 0 10, 0 0))', 4326);
SELECT @g.STIsValid() AS before_valid, @g.MakeValid().STIsValid() AS after_valid;
go

DECLARE @g geography;
SET @g = geography::STGeomFromText('MULTIPOLYGON(((0 0, 0 5, 5 5, 5 0, 0 0)), ((10 10, 10 15, 15 15, 15 10, 10 10)))', 4326);
SELECT @g.MakeValid().STAsText() AS result, @g.MakeValid().STIsValid() AS is_valid;
go

DECLARE @g geography;
SET @g = geography::STGeomFromText('POLYGON((0 0, 10 10, 10 0, 0 10, 0 0))', 4326);
SELECT @g.MakeValid().STArea() AS area;
go


DECLARE @g geography;
SET @g = geography::STGeomFromText('POLYGON((0 0, 10 10, 10 0, 0 10, 0 0))', 4326);
SELECT @g . MakeValid ( ) . STIsValid ( ) AS is_valid;
go

DECLARE @g geography;
SET @g = geography::STGeomFromText('POLYGON((0 0, 10 10, 10 0, 0 10, 0 0))', 4326);
SELECT @g.MakeValid().MakeValid().STIsValid() AS is_valid;
go

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

SELECT ID, Description, GeomColumn.STIsValid() AS BeforeValid, GeomColumn.MakeValid().STIsValid() AS AfterValid 
FROM TestSpatialFunc3_MakeValidGeomTemp 
WHERE GeomColumn.STIsValid() = 0 
ORDER BY ID;
go

SELECT ID, Description, GeomColumn.MakeValid().STAsText() AS MadeValid 
FROM TestSpatialFunc3_MakeValidGeomTemp 
WHERE GeomColumn.STIsValid() = 1 
ORDER BY ID;
go

SELECT ID, Description, GeomColumn.MakeValid() AS MadeValid 
FROM TestSpatialFunc3_MakeValidGeomTemp 
WHERE GeomColumn IS NULL 
ORDER BY ID;
go

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

DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 0 10, 10 10, 10 0))', 0);
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('LINESTRING(0 0, 0 0, 10 10, 10 10, 20 20)', 0);
SELECT @g.MakeValid().STAsText();
go


DECLARE @g geometry = geometry::STGeomFromText('LINESTRING(0 0, 10 10, 10 0, 0 10)', 0);
SELECT @g.MakeValid().STAsText();
go


DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0), (20 20, 20 25, 25 25, 25 20, 20 20))', 0);
SELECT @g.MakeValid().STAsText();
go


DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 0 20, 20 20, 20 0, 0 0), (2 2, 2 10, 10 10, 10 2, 2 2), (5 5, 5 15, 15 15, 15 5, 5 5))', 0);
SELECT @g.MakeValid().STAsText();
go


DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 0 20, 20 20, 20 0, 0 0), (5 5, 15 5, 15 15, 5 15, 5 5))', 0);
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 10 0, 10 10, 5 5.0001, 10 10, 0 10, 0 0))', 0);
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 10 0, 10 0, 0 0))', 0);
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('LINESTRING(5 5, 5 5)', 0);
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('POINT(10 20 30)', 0);
SELECT @g.MakeValid().STAsText(), @g.MakeValid().HasZ;
go

DECLARE @g geometry = geometry::STGeomFromText('POINT(10 20 NULL 40)', 0);
SELECT @g.MakeValid().STAsText(), @g.MakeValid().HasM;
go

DECLARE @g geometry = geometry::STGeomFromText('LINESTRING(0 0 0, 10 10 10, 20 20 20)', 0);
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0 0, 10 10 10, 10 0 5, 0 10 5, 0 0 0))', 0);
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('POINT(1000000000 1000000000)', 0);
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('POINT(0.000000001 0.000000001)', 0);
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('POLYGON((-10 -10, -10 10, 10 10, 10 -10, -10 -10))', 0);
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('POLYGON((-5 -5, -5 5, 5 5, 5 -5, -5 -5))', 0);
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('POLYGON((5 5, 5 5, 5 5, 5 5))', 0);
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 5 0, 10 0, 5 0, 0 0))', 0);
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))', 0); 
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 5 10, 10 0, 10 10, 5 10, 0 10, 0 0))', 0);
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 0 10, 10 10, 10 0.0000001, 10 0, 0 0))', 0);
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geography = geography::STGeomFromText('LINESTRING(170 0, -170 0)', 4326);
SELECT @g.MakeValid().STAsText();
go

DECLARE @g geography = geography::Point(89.999, 0, 4326);
SELECT @g.MakeValid().STAsText();
go

SELECT geometry::STGeomFromText('POLYGON((0 0,10 10,10 0,0 10,0 0))', 0).MakeValid().STAsText();
go

DECLARE @g geometry = geometry::STGeomFromText('POLYGON((0 0, 0 20, 20 20, 20 0, 0 0), (5 5, 15 5, 15 15, 5 15, 5 5))', 0);
SELECT @g.MakeValid().STAsText();
go