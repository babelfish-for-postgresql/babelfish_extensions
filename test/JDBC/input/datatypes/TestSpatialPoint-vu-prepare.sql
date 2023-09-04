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

-- Negative Test for STGeomFromText when SRID is null
-- BabelFish returns Null NBCROW, but it should throw ' 'geometry::STGeomFromText' failed because parameter 2 is not allowed to be null. The statement has been terminated.'
-- INSERT INTO SPATIALPOINTGEOM_dt (location)
-- VALUES ( geometry::STGeomFromText('Point(47.65100 -22.34900)', null ) )
-- GO

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

CREATE TABLE SPATIALPOINTGEOG_dt (location geography)
GO

-- Geography Test Cases

-- Positive Test for STGeomFromText with SRID 4326
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::STGeomFromText('Point(47.65100 -22.34900)', 4326) )
GO
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::STGeomFromText('Point(1.0 2.0)', 4326) )
GO

-- Positive Test for STGeomFromText with SRID 0
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::STGeomFromText('Point(47.65100 -22.34900)', 0) )
GO

-- Negative Test for STGeomFromText when SRID is not provided
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::STGeomFromText('Point(47.65100 -22.34900)') )
GO

-- Negative Test for STGeomFromText when SRID is null
-- BabelFish returns Null NBCROW, but it should throw ' 'geometry::STGeomFromText' failed because parameter 2 is not allowed to be null. The statement has been terminated.'
-- INSERT INTO SPATIALPOINTGEOG_dt (location)
-- VALUES ( geography::STGeomFromText('Point(47.65100 -22.34900)', null ) )
-- GO

-- Negative Test for STGeomFromText when SRID >= 10^6
-- SRID should be between 0 to 999999
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::STGeomFromText('Point(47.65100 -22.34900)', 1000000000 ) )
GO

-- Negative Test for STGeomFromText with SRID < 0
-- SRID should be between 0 to 999999
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

-- Positive Test for Point with SRID 4326
INSERT INTO SPATIALPOINTGEOG_dt (location)
VALUES ( geography::Point(47.65100, -22.34900, 4326) )
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