CREATE TYPE dbo.babel_5987_xmlUDT FROM XML;
GO

CREATE TYPE dbo.babel_5987_geometryUDT FROM geometry;
GO

CREATE TYPE dbo.babel_5987_geographyUDT FROM geography;
GO

CREATE TABLE babel_5987_colon_colon_t1 (XmlColumn XML, GeomColumn geometry, GeogColumn geography)
GO

INSERT INTO babel_5987_colon_colon_t1
VALUES ('<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>', 
        geometry::STGeomFromText('POINT (1 2)', 0), 
        geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326))
GO
