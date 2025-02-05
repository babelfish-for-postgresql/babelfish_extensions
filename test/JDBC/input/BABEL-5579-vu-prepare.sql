

CREATE DATABASE TestGeospatialMethods_DB;
GO

USE TestGeospatialMethods_DB;
GO

CREATE TABLE TestGeospatialMethods_YourTable1Temp ( ID INT PRIMARY KEY, PointColumn geometry ); 
INSERT INTO TestGeospatialMethods_YourTable1Temp (ID, PointColumn) VALUES (1, geometry::Point(3.0, 4.0, 4326)), (2, geometry::Point(5.0, 6.0, 4326)), (3, geometry::Point(3.0, 4.0, 0));
go

CREATE DATABASE TestGeospatialMethodstemp_DB;
GO

USE TestGeospatialMethodstemp_DB;
GO


CREATE TABLE TestGeospatialMethods_YourTableTemp ( ID INT PRIMARY KEY, PointColumn geometry ); 
INSERT INTO TestGeospatialMethods_YourTableTemp (ID, PointColumn) VALUES (1, geometry::Point(3.0, 4.0, 4326)), (2, geometry::Point(5.0, 6.0, 4326)), (3, geometry::Point(3.0, 4.0, 0));
go

CREATE TABLE TestGeospatialMethods_YourTable2Temp ( ID INT PRIMARY KEY, PointColumn1 geometry, PointColumn2 geometry ); 
INSERT INTO TestGeospatialMethods_YourTable2Temp (ID, PointColumn1, PointColumn2) VALUES (1, geometry::Point(3.0, 4.0, 4326), geometry::Point(3.0, 4.0, 4326));
go

CREATE TABLE TestGeospatialMethods_TableATemp (ID INT PRIMARY KEY, PointA geometry); 
INSERT INTO TestGeospatialMethods_TableATemp (ID, PointA) VALUES (1, geometry::Point(1.0, 2.0, 4326)); 
go

CREATE TABLE TestGeospatialMethods_TableBTemp (ID INT PRIMARY KEY, PointB geometry);
INSERT INTO TestGeospatialMethods_TableBTemp (ID, PointB) VALUES (1, geometry::Point(3.0, 4.0, 4326));
go

CREATE TABLE TestGeospatialMethods_SPATIALPOINTGEOG_dttemp (location geography);
INSERT INTO TestGeospatialMethods_SPATIALPOINTGEOG_dttemp (location) VALUES ( geography::STGeomFromText('Point(47.65100 -22.34900)', 4326) );
INSERT INTO TestGeospatialMethods_SPATIALPOINTGEOG_dttemp (location) VALUES ( geography::STGeomFromText('Point(1.0 2.0)', 4326) );
INSERT INTO TestGeospatialMethods_SPATIALPOINTGEOG_dttemp (location) VALUES ( geography::STGeomFromText('Point(1.0 2.0)', 4326) );
INSERT INTO TestGeospatialMethods_SPATIALPOINTGEOG_dttemp (location) VALUES ( geography::STPointFromText('Point(1.0 2.0)', 4326) );
go

CREATE TABLE TestGeospatialMethods_SPATIALPOINTGEOM_dttemp (location geometry);
INSERT INTO TestGeospatialMethods_SPATIALPOINTGEOM_dttemp (location) VALUES ( geometry::STGeomFromText('Point(47.65100 -22.34900)', 4326) );
INSERT INTO TestGeospatialMethods_SPATIALPOINTGEOM_dttemp (location) VALUES ( geometry::STGeomFromText('Point(1.0 2.0)', 4326) );
INSERT INTO TestGeospatialMethods_SPATIALPOINTGEOM_dttemp (location) VALUES ( geometry::STGeomFromText('Point(47.65100 -22.34900)', 0) );
INSERT INTO TestGeospatialMethods_SPATIALPOINTGEOM_dttemp (location) VALUES ( geometry::STPointFromText('Point(1.0 2.0)', 4326) );
INSERT INTO TestGeospatialMethods_SPATIALPOINTGEOM_dttemp (location) VALUES ( geometry::Point(47.65100, -22.34900, 4326) );
go

CREATE VIEW TestGeospatialMethods_point_intersect1Temp AS SELECT p1.location.STIntersects(p2.location) AS intersection FROM TestGeospatialMethods_SPATIALPOINTGEOM_dttemp p1 CROSS JOIN TestGeospatialMethods_SPATIALPOINTGEOM_dttemp p2;
go
CREATE VIEW TestGeospatialMethods_disjointTemp AS SELECT p1.location.STDisjoint(p2.location) AS isIN FROM TestGeospatialMethods_SPATIALPOINTGEOM_dttemp p1 CROSS JOIN TestGeospatialMethods_SPATIALPOINTGEOM_dttemp p2 ORDER BY p1.location.STX;
go
CREATE VIEW TestGeospatialMethods_ValFromGeomTemp AS SELECT location.STDimension() FROM TestGeospatialMethods_SPATIALPOINTGEOM_dttemp ORDER BY location.STX;
go
CREATE VIEW TestGeospatialMethods_TextFromGeogTemp AS SELECT  location.STDimension() AS Dimension FROM TestGeospatialMethods_SPATIALPOINTGEOG_dttemp ORDER BY location.Lat;
go
CREATE VIEW TestGeospatialMethods_point_intersectTemp AS SELECT p1.location.STIntersects(p2.location) AS Intersection FROM TestGeospatialMethods_SPATIALPOINTGEOG_dttemp p1 CROSS JOIN TestGeospatialMethods_SPATIALPOINTGEOG_dttemp p2 ORDER BY p1.location.Lat;
go
CREATE VIEW TestGeospatialMethods_point_disjointTemp AS SELECT p1.location.STDisjoint(p2.location) AS isIn FROM TestGeospatialMethods_SPATIALPOINTGEOG_dttemp p1 CROSS JOIN TestGeospatialMethods_SPATIALPOINTGEOG_dttemp p2;
go
