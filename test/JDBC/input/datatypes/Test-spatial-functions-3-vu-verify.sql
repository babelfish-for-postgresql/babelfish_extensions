
USE TestGeospatialMethods3_DB;
go

--  View - Geometry
SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOM_View_db ORDER BY ID;
go

--  View - Geography
SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOG_View_db ORDER BY ID;
go

-- WHERE - Geometry
SELECT ID, GeomColumn.STGeometryType() AS GeomType
FROM TestGeospatialMethods3_STGeometryType_GEOM_db
WHERE GeomColumn.STGeometryType() = 'Point'
ORDER BY ID;
go

--  WHERE - Geography
SELECT ID, GeogColumn.STGeometryType() AS GeogType
FROM TestGeospatialMethods3_STGeometryType_GEOG_db
WHERE GeogColumn.STGeometryType() = 'Point'
ORDER BY ID;
go

--  ORDER BY - Geometry
SELECT ID, GeomColumn.STGeometryType() AS GeomType
FROM TestGeospatialMethods3_STGeometryType_GEOM_db
ORDER BY GeomColumn.STGeometryType() ASC, ID ASC;
go

--  ORDER BY - Geography
SELECT ID, GeogColumn.STGeometryType() AS GeogType
FROM TestGeospatialMethods3_STGeometryType_GEOG_db
ORDER BY GeogColumn.STGeometryType() DESC;
go

--  GROUP BY - Geometry
SELECT GeomColumn.STGeometryType() AS GeomType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOM_db
GROUP BY GeomColumn.STGeometryType()
ORDER BY GeomType;
go

--  GROUP BY - Geography
SELECT GeogColumn.STGeometryType() AS GeogType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOG_db
GROUP BY GeogColumn.STGeometryType()
ORDER BY GeogType;
go

--  HAVING - Geometry
SELECT GeomColumn.STGeometryType() AS GeomType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOM_db
GROUP BY GeomColumn.STGeometryType()
HAVING COUNT(*) > 1
ORDER BY GeomType;
go

--  JOIN on ID
SELECT g.ID, g.GeomColumn.STGeometryType() AS GeomType,
       geo.GeogColumn.STGeometryType() AS GeogType
FROM TestGeospatialMethods3_STGeometryType_GEOM_db g
JOIN TestGeospatialMethods3_STGeometryType_GEOG_db geo ON g.ID = geo.ID
ORDER BY g.ID;
go

--  JOIN on STGeometryType match
SELECT g.ID AS GeomID, geo.ID AS GeogID,
       g.GeomColumn.STGeometryType() AS MatchedType
FROM TestGeospatialMethods3_STGeometryType_GEOM_db g
JOIN TestGeospatialMethods3_STGeometryType_GEOG_db geo
  ON g.GeomColumn.STGeometryType() = geo.GeogColumn.STGeometryType()
ORDER BY g.ID, geo.ID;
go

--  JOIN views
SELECT gv.ID, gv.GeomType, ggv.GeogType
FROM TestGeospatialMethods3_STGeometryType_GEOM_View_db gv
JOIN TestGeospatialMethods3_STGeometryType_GEOG_View_db ggv ON gv.ID = ggv.ID
ORDER BY gv.ID;
go

--  CTE - Geometry
WITH GeomCTE AS (
    SELECT ID, GeomColumn.STGeometryType() AS GeomType
    FROM TestGeospatialMethods3_STGeometryType_GEOM_db
)
SELECT * FROM GeomCTE WHERE GeomType = 'Point' ORDER BY ID;
go

--  CTE - Geography
WITH GeogCTE AS (
    SELECT ID, GeogColumn.STGeometryType() AS GeogType
    FROM TestGeospatialMethods3_STGeometryType_GEOG_db
)
SELECT * FROM GeogCTE WHERE GeogType = 'Polygon' ORDER BY ID;
go

--  CTE Combined
WITH GeomCTE AS (
    SELECT ID, GeomColumn.STGeometryType() AS GeomType
    FROM TestGeospatialMethods3_STGeometryType_GEOM_db
),
GeogCTE AS (
    SELECT ID, GeogColumn.STGeometryType() AS GeogType
    FROM TestGeospatialMethods3_STGeometryType_GEOG_db
)
SELECT g.ID, g.GeomType, gg.GeogType
FROM GeomCTE g
JOIN GeogCTE gg ON g.ID = gg.ID
ORDER BY g.ID;
go

--  Window ROW_NUMBER - Geometry
SELECT ID, GeomColumn.STGeometryType() AS GeomType,
       ROW_NUMBER() OVER (ORDER BY GeomColumn.STGeometryType()) AS RowNum
FROM TestGeospatialMethods3_STGeometryType_GEOM_db
ORDER BY RowNum;
go

--  Window COUNT PARTITION - Geometry
SELECT ID, GeomColumn.STGeometryType() AS GeomType,
       COUNT(*) OVER (PARTITION BY GeomColumn.STGeometryType()) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOM_db
ORDER BY ID;
go

--  Window LAG/LEAD - Geography
SELECT ID, GeogColumn.STGeometryType() AS GeogType,
       LAG(GeogColumn.STGeometryType()) OVER (ORDER BY ID) AS PrevType,
       LEAD(GeogColumn.STGeometryType()) OVER (ORDER BY ID) AS NextType
FROM TestGeospatialMethods3_STGeometryType_GEOG_db
ORDER BY ID;
go

--  Subquery - Geometry
SELECT * FROM (
    SELECT ID, GeomColumn.STGeometryType() AS GeomType
    FROM TestGeospatialMethods3_STGeometryType_GEOM_db
) AS Sub
WHERE GeomType = 'Polygon'
ORDER BY ID;
go

-- 20. CASE - Geometry
SELECT ID,
    CASE GeomColumn.STGeometryType()
        WHEN 'Point' THEN 'Zero Dimensional'
        WHEN 'LineString' THEN 'One Dimensional'
        WHEN 'Polygon' THEN 'Two Dimensional'
        ELSE 'Unknown'
    END AS DimensionType
FROM TestGeospatialMethods3_STGeometryType_GEOM_db
ORDER BY ID;
go

--  CTE + Window Combined - Geometry
WITH RankedGeom AS (
    SELECT ID, GeomColumn.STGeometryType() AS GeomType,
           ROW_NUMBER() OVER (ORDER BY GeomColumn.STGeometryType(), ID) AS RowNum,
           COUNT(*) OVER (PARTITION BY GeomColumn.STGeometryType()) AS TypeCount
    FROM TestGeospatialMethods3_STGeometryType_GEOM_db
)
SELECT * FROM RankedGeom ORDER BY RowNum;
go

--  WHERE + GROUP BY + ORDER BY Combined
SELECT GeomColumn.STGeometryType() AS GeomType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOM_db
WHERE GeomColumn.STGeometryType() != 'Point'
GROUP BY GeomColumn.STGeometryType()
ORDER BY TypeCount DESC, GeomType ASC;
go

-- View WHERE
SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOM_View_db
WHERE GeomType = 'Point'
ORDER BY ID;
go

SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOG_View_db
WHERE GeogType = 'Polygon'
ORDER BY ID;
go

-- View ORDER BY
SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOM_View_db
ORDER BY GeomType ASC, ID ASC;
go

-- View GROUP BY
SELECT GeomType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOM_View_db
GROUP BY GeomType
ORDER BY GeomType;
go

SELECT GeogType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOG_View_db
GROUP BY GeogType
ORDER BY GeogType;
go

-- View Subquery
SELECT * FROM (
    SELECT ID, GeomType FROM TestGeospatialMethods3_STGeometryType_GEOM_View_db
) AS Sub
WHERE GeomType = 'Polygon'
ORDER BY ID;
go


-- MASTER DATABASE TESTS

USE MASTER;
go

-- Inline Geometry Tests
SELECT geometry::STGeomFromText('POINT(1 2)', 4326).STGeometryType();
go

SELECT geometry::STGeomFromText('LINESTRING(0 0, 1 1, 2 2)', 4326).STGeometryType();
go

SELECT geometry::STGeomFromText('POLYGON((0 0, 4 0, 4 4, 0 4, 0 0))', 4326).STGeometryType();
go

SELECT geometry::STPointFromText('POINT EMPTY', 4326).STGeometryType();
go

SELECT geometry::Point(3.0, 4.0, 4326).STGeometryType();
go

-- Inline Geography Tests
SELECT geography::STGeomFromText('POINT(-122.34 47.65)', 4326).STGeometryType();
go

SELECT geography::STGeomFromText('LINESTRING(-122.36 47.65, -122.34 47.66, -122.32 47.65)', 4326).STGeometryType();
go

SELECT geography::STGeomFromText('POLYGON((-122.35 47.64, -122.33 47.64, -122.33 47.66, -122.35 47.66, -122.35 47.64))', 4326).STGeometryType();
go

SELECT geography::STPointFromText('POINT EMPTY', 4326).STGeometryType();
go

SELECT geography::Point(47.65, -122.34, 4326).STGeometryType();
go

-- Table SELECT / WHERE / GROUP BY - Geometry
SELECT ID, GeomColumn.STGeometryType() AS GeometryType
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
ORDER BY ID;
go

SELECT ID, GeomColumn.STGeometryType() AS GeometryType
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
WHERE GeomColumn.STGeometryType() = 'Point'
ORDER BY ID;
go

SELECT GeomColumn.STGeometryType() AS GeometryType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
GROUP BY GeomColumn.STGeometryType()
ORDER BY GeometryType;
go

-- Table SELECT / WHERE / GROUP BY - Geography
SELECT ID, GeogColumn.STGeometryType() AS GeographyType
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp
ORDER BY ID;
go

SELECT ID, GeogColumn.STGeometryType() AS GeographyType
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp
WHERE GeogColumn.STGeometryType() = 'Point'
ORDER BY ID;
go

SELECT GeogColumn.STGeometryType() AS GeographyType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp
GROUP BY GeogColumn.STGeometryType()
ORDER BY GeographyType;
go

-- View Tests
SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOM_View_Temp ORDER BY ID;
go

SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOG_View_Temp ORDER BY ID;
go

-- Variable Tests
DECLARE @geom geometry = geometry::STGeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))', 4326);
SELECT @geom.STGeometryType();
go

DECLARE @geog geography = geography::STGeomFromText('LINESTRING(-122.36 47.65, -122.34 47.66)', 4326);
SELECT @geog.STGeometryType();
go

-- Combined with STDimension
SELECT GeomColumn.STGeometryType() AS GeomType, GeomColumn.STDimension() AS Dimension
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
ORDER BY ID;
go

SELECT GeogColumn.STGeometryType() AS GeogType, GeogColumn.STDimension() AS Dimension
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp
ORDER BY ID;
go

-- Combined with STIsEmpty
SELECT GeomColumn.STGeometryType() AS GeomType, GeomColumn.STIsEmpty() AS IsEmpty
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
ORDER BY ID;
go

SELECT GeogColumn.STGeometryType() AS GeogType, GeogColumn.STIsEmpty() AS IsEmpty
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp
ORDER BY ID;
go

-- Different SRIDs
SELECT geometry::STGeomFromText('POINT(1 2)', 0).STGeometryType();
go

SELECT geography::STGeomFromText('POINT(-122.34 47.65)', 4269).STGeometryType();
go

-- NULL Tests
DECLARE @nullGeom geometry = NULL;
SELECT @nullGeom.STGeometryType();
go

DECLARE @nullGeog geography = NULL;
SELECT @nullGeog.STGeometryType();
go

-- ORDER BY on function result
SELECT ID, GeomColumn.STGeometryType() AS GeometryType
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
ORDER BY GeomColumn.STGeometryType(), ID;
go

-- CASE Statement
SELECT ID,
    CASE GeomColumn.STGeometryType()
        WHEN 'Point' THEN 'Zero Dimensional'
        WHEN 'LineString' THEN 'One Dimensional'
        WHEN 'Polygon' THEN 'Two Dimensional'
        ELSE 'Unknown'
    END AS DimensionType
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
ORDER BY ID;
go

-- Subquery
SELECT * FROM (
    SELECT ID, GeomColumn.STGeometryType() AS GeomType
    FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
) AS SubQuery
WHERE GeomType = 'Point'
ORDER BY ID;
go

-- JOIN Geometry to Geography
SELECT g.ID AS GeomID, geo.ID AS GeogID,
       g.GeomColumn.STGeometryType() AS GeomType,
       geo.GeogColumn.STGeometryType() AS GeogType
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp g
JOIN TestGeospatialMethods3_STGeometryType_GEOG_Temp geo ON g.ID = geo.ID
ORDER BY g.ID;
go

-- Edge Cases: Z, ZM, extreme coordinates
SELECT geometry::STGeomFromText('LINESTRING ZM(0 0 0 0, 1 1 1 1, 2 2 2 2)', 4326).STGeometryType();
go

SELECT geography::STGeomFromText('POLYGON((-122.35 47.64 0, -122.33 47.64 0, -122.33 47.66 0, -122.35 47.66 0, -122.35 47.64 0))', 4326).STGeometryType();
go

SELECT geography::STGeomFromText('POINT ZM(-122.34 47.65 100 200)', 4326).STGeometryType();
go

SELECT geometry::STGeomFromText('POINT(0.0000001 0.0000001)', 4326).STGeometryType();
go

SELECT geometry::STGeomFromText('POINT(999999999 999999999)', 0).STGeometryType();
go

SELECT geometry::STGeomFromText('POINT(-100 -200)', 4326).STGeometryType();
go

-- First 3 chars should NOT be 'ST_'

DECLARE @pt geometry = geometry::STGeomFromText('POINT(1 2)', 4326);
DECLARE @ln geometry = geometry::STGeomFromText('LINESTRING(0 0, 1 1)', 4326);
DECLARE @pg geometry = geometry::STGeomFromText('POLYGON((0 0, 4 0, 4 4, 0 4, 0 0))', 4326);

SELECT 'Point' AS Type,
       @pt.STGeometryType() AS ReturnedValue,
       CASE WHEN LEFT(@pt.STGeometryType(), 3) = 'ST_' THEN 'FAIL' ELSE 'PASS' END AS PrefixCheck
UNION ALL
SELECT 'LineString',
       @ln.STGeometryType(),
       CASE WHEN LEFT(@ln.STGeometryType(), 3) = 'ST_' THEN 'FAIL' ELSE 'PASS' END
UNION ALL
SELECT 'Polygon',
       @pg.STGeometryType(),
       CASE WHEN LEFT(@pg.STGeometryType(), 3) = 'ST_' THEN 'FAIL' ELSE 'PASS' END
ORDER BY Type;
go

-- Geography: Verify no ST_ prefix on all types
DECLARE @gpt geography = geography::STGeomFromText('POINT(-122.34 47.65)', 4326);
DECLARE @gln geography = geography::STGeomFromText('LINESTRING(-122.36 47.65, -122.34 47.66)', 4326);
DECLARE @gpg geography = geography::STGeomFromText('POLYGON((-122.35 47.64, -122.33 47.64, -122.33 47.66, -122.35 47.66, -122.35 47.64))', 4326);

SELECT 'Point' AS Type,
       @gpt.STGeometryType() AS ReturnedValue,
       CASE WHEN LEFT(@gpt.STGeometryType(), 3) = 'ST_' THEN 'FAIL' ELSE 'PASS' END AS PrefixCheck
UNION ALL
SELECT 'LineString',
       @gln.STGeometryType(),
       CASE WHEN LEFT(@gln.STGeometryType(), 3) = 'ST_' THEN 'FAIL' ELSE 'PASS' END
UNION ALL
SELECT 'Polygon',
       @gpg.STGeometryType(),
       CASE WHEN LEFT(@gpg.STGeometryType(), 3) = 'ST_' THEN 'FAIL' ELSE 'PASS' END
ORDER BY Type;
go


-- Verify no row in table has ST_ prefix in result
SELECT ID, GeomColumn.STGeometryType() AS GeomType
FROM TestGeospatialMethods3_STGeometryType_GEOM_Temp
WHERE GeomColumn.STGeometryType() LIKE 'ST[_]%'
ORDER BY ID;
go


SELECT ID, GeogColumn.STGeometryType() AS GeogType
FROM TestGeospatialMethods3_STGeometryType_GEOG_Temp
WHERE GeogColumn.STGeometryType() LIKE 'ST[_]%'
ORDER BY ID;
go


-- NEGATIVE CHECK: Verify ST_ prefix is NOT returned
SELECT 'BUG: ST_ prefix not stripped' AS Result
WHERE geometry::STGeomFromText('POINT(1 2)', 4326).STGeometryType() LIKE 'ST[_]%';
go

SELECT 'BUG: ST_ prefix not stripped' AS Result
WHERE geography::STGeomFromText('POINT(-122.34 47.65)', 4326).STGeometryType() LIKE 'ST[_]%';
go


-- View WHERE
SELECT * FROM TestGeospatialMethods3_STGeometryType_GEOM_View_Temp
WHERE GeomType = 'Point'
ORDER BY ID;
go

-- View GROUP BY
SELECT GeomType, COUNT(*) AS TypeCount
FROM TestGeospatialMethods3_STGeometryType_GEOM_View_Temp
GROUP BY GeomType
ORDER BY GeomType;
go

-- UNION ALL geometry + geography
DECLARE @geom geometry = geometry::STGeomFromText('LINESTRING(0 0, 10 10)', 4326);
DECLARE @geog geography = geography::STGeomFromText('POINT(-122.34 47.65)', 4326);
SELECT 'Geometry' AS Source, @geom.STGeometryType() AS Type
UNION ALL
SELECT 'Geography', @geog.STGeometryType();
ORDER BY Source;
go

-- SRID 999999
SELECT geometry::STGeomFromText('POINT(1 2)', 999999).STGeometryType();
go