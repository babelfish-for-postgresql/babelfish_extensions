CREATE TABLE SPATIALPOINTGEOM_dt (location geometry)
GO

-- Geometry Test Cases

-- Positive Test for STGeomFromText with SRID 4326
INSERT INTO SPATIALPOINTGEOM_dt (location)
VALUES ( geometry::STGeomFromText('Point(47.65100 -22.34900)', 4326) )
GO
INSERT INTO SPATIALPOINTGEOM_dt (location)
VALUES ( geometry::STGeomFromText('Point(1.0 2.0)', 4326) )
GO

-- Positive Test for STGeomFromText with SRID 0
INSERT INTO SPATIALPOINTGEOM_dt (location)
VALUES ( geometry::STGeomFromText('Point(47.65100 -22.34900)', 0) )
GO

-- Negative Test for STGeomFromText when SRID is not provided
INSERT INTO SPATIALPOINTGEOM_dt (location)
VALUES ( geometry::STGeomFromText('Point(47.65100 -22.34900)') )
GO

-- Negative Test for STGeomFromText when SRID >= 10^6
-- SRID should be between 0 to 999999
INSERT INTO SPATIALPOINTGEOM_dt (location)
VALUES ( geometry::STGeomFromText('Point(47.65100 -22.34900)', 1000000000 ) )
GO

-- Negative Test for STGeomFromText with SRID < 0
-- SRID should be between 0 to 999999
INSERT INTO SPATIALPOINTGEOM_dt (location)
VALUES ( geometry::STGeomFromText('Point(47.65100 -22.34900)', -1) )
GO

-- Negative Test for STGeomFromText when a coordinate is missing
INSERT INTO SPATIALPOINTGEOM_dt (location)
VALUES ( geometry::STGeomFromText('Point(1.0 )', 4326) )
GO

-- Negative Test for STGeomFromText when invalid type is provided
INSERT INTO SPATIALPOINTGEOM_dt (location)
VALUES ( geometry::STGeomFromText('Pnt', 4326) )
GO

-- Test for STGeomFromText when null Point is Given -> Returns NBCRow
INSERT INTO SPATIALPOINTGEOM_dt (location)
VALUES ( geometry::STGeomFromText(null, 4326) )
GO

-- -- Negative Test for STGeomFromText when Incorrect cast is provided
-- INSERT INTO SPATIALPOINTGEOM_dt (location)
-- VALUES ( geography::STGeomFromText('Point(47.65100 -22.34900)', 4326) )
-- GO

-- Positive Test for STPointFromText with SRID 4326. Rest are same as STGeomFromText
INSERT INTO SPATIALPOINTGEOM_dt (location)
VALUES ( geometry::STPointFromText('Point(47.65100 -22.34900)', 4326) )
GO
INSERT INTO SPATIALPOINTGEOM_dt (location)
VALUES ( geometry::STPointFromText('Point(1.0 2.0)', 4326) )
GO

-- Positive Test for Point with SRID 4326
INSERT INTO SPATIALPOINTGEOM_dt (location)
VALUES ( geometry::Point(47.65100, -22.34900, 4326) )
GO

CREATE VIEW TextFromGeom AS
SELECT STAsText(location) AS TextRepresentation
FROM SPATIALPOINTGEOM_dt;
GO

CREATE VIEW BinaryFromGeom AS
SELECT STAsBinary(location) AS BinaryRepresentation
FROM SPATIALPOINTGEOM_dt;
GO

CREATE VIEW CoordsFromGeom AS
SELECT STX(location), STY(location)  AS Coordinates
FROM SPATIALPOINTGEOM_dt;
GO

CREATE VIEW point_distances_geom AS
SELECT
    p1.location AS point1,
    p2.location AS point2,
    STDistance( p1.location, p2.location ) AS distance
FROM
    SPATIALPOINTGEOM_dt p1
CROSS JOIN
    SPATIALPOINTGEOM_dt p2
WHERE
    p1.location <> p2.location;
GO

CREATE TABLE SPATIALPOINTGEOG_dt (location geography)
GO

-- Create Type Test Case currently Babelfish supports it but TSQL doesn't for spatial Types, Although it doesn't break anything
-- TODO: Make it similar to T-SQL
CREATE TYPE geom
FROM geometry NOT NULL ;
GO

CREATE TABLE TypeTable(ID INT PRIMARY KEY, Shape geom)
GO

INSERT INTO TypeTable(ID, Shape)
VALUES(1, geometry::Point(1, 2, 4326));
GO

-- Geography Test Cases

-- Positive Test for STGeomFromText with SRID 4326
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::STGeomFromText('Point(47.65100 -22.34900)', 4326) )
GO
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::STGeomFromText('Point(1.0 2.0)', 4326) )
GO

-- Negative Test for STGeomFromText for Geography with SRID 0
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::STGeomFromText('Point(47.65100 -22.34900)', 0) )
GO

-- Negative Test for STGeomFromText for Geography when lat > 90 or < -90
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::STGeomFromText('Point(47.65100 -122.34900)', 4326) )
GO

-- Negative Test for STGeomFromText when SRID is not provided
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::STGeomFromText('Point(47.65100 -22.34900)') )
GO

-- Negative Test for STGeomFromText when cast is not provided
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( STGeomFromText('Point(47.65100 -22.34900)', 4326) )
GO

-- -- Negative Test for STGeomFromText when incorrect cast is provided
-- INSERT INTO SPATIALPOINTGEOG_dt (location)
-- VALUES ( geometry::STGeomFromText('Point(47.65100 -22.34900)', 4326) )
-- GO

-- Negative Test for STGeomFromText when SRID >= 10^6
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::STGeomFromText('Point(47.65100 -22.34900)', 1000000000 ) )
GO

-- Negative Test for STGeomFromText with SRID < 0
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::STGeomFromText('Point(47.65100 -22.34900)', -1) )
GO

-- Negative Test for STGeomFromText when a coordinate is missing
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::STGeomFromText('Point(1.0 )', 4326) )
GO

-- Negative Test for STGeomFromText when invalid type is provided
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::STGeomFromText('Pnt', 4326) )
GO

-- Test for STGeomFromText when null Point is Given -> Returns NBCRow
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::STGeomFromText(null, 4326) )
GO

-- Positive Test for STPointFromText with SRID 4326. Rest are same as STGeomFromText
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::STPointFromText('Point(47.65100 -22.34900)', 4326) )
GO
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::STPointFromText('Point(1.0 2.0)', 4326) )
GO

-- Negative Test for STPointFromText for Geography when lat > 90 or < -90
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::STPointFromText('Point(47.65100 122.34900)', 4326) )
GO

-- Positive Test for Point with SRID 4326
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::Point(47.65100, -22.34900, 4326) )
GO

-- Negative Test for Point for Geography when lat > 90 or < -90
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::Point(147.65100, -22.34900, 4326) )
GO

CREATE VIEW TextFromGeog AS
SELECT STAsText(location) AS TextRepresentation
FROM SPATIALPOINTGEOG_dt;
GO

CREATE VIEW BinaryFromGeog AS
SELECT STAsBinary(location) AS BinaryRepresentation
FROM SPATIALPOINTGEOG_dt;
GO

CREATE VIEW CoordsFromGeog AS
SELECT long(location), lat(location)  AS Coordinates
FROM SPATIALPOINTGEOG_dt;
GO


CREATE VIEW TransformFromGeog AS
SELECT ST_Transform(location, 4326) AS Modified_points
FROM SPATIALPOINTGEOG_dt;
GO

CREATE VIEW point_distances_geog AS
SELECT
    p1.location AS point1,
    p2.location AS point2,
    STDistance( p1.location, p2.location ) AS distance
FROM
    SPATIALPOINTGEOG_dt p1
CROSS JOIN
    SPATIALPOINTGEOG_dt p2
WHERE
    p1.location <> p2.location;
GO

CREATE TABLE SPATIALPOINT_dt (GeomColumn geometry, GeogColumn geography)
GO
INSERT INTO SPATIALPOINT_dt (GeomColumn)
VALUES ( geometry::STGeomFromText('Point(47.65100 -22.34900)', 4326) )
GO
INSERT INTO SPATIALPOINT_dt (GeogColumn)
VALUES ( geography::STGeomFromText('Point(47.65100 -22.34900)', 4326) )
GO
INSERT INTO SPATIALPOINT_dt (GeomColumn, GeogColumn)
VALUES ( geometry::STGeomFromText('Point(1.0 2.0)', 4326), geography::STGeomFromText('Point(1.0 2.0)', 4326) )
GO
