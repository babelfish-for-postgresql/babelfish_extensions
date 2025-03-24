
-- STGeomFromText tests
SELECT geometry::STGeomFromText('POINT(10 20)', 4326) ;
GO
  
SELECT geometry::STGeomFromText('POINT(10 20 30)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL)', 4311);
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 1)', 0); 
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL 1)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 NULL)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL NULL)', 4326);
GO

SELECT geometry::STGeomFromText('POINT EMPTY',1000);  
GO

-- STPointFromText tests
SELECT geometry::STPointFromText('POINT(10 20)', 4326);
GO

SELECT geometry::STPointFromText('POINT(10 20 30)', 4326);
GO

SELECT geometry::STPointFromText('POINT(10 20 NULL)', 5123);
GO

SELECT geometry::STPointFromText('POINT(10 20 30 1)', 4326);
GO

SELECT geometry::STPointFromText('POINT(10 20 NULL 1)', 4326);
GO

SELECT geometry::STPointFromText('POINT(10 20 30 NULL)', 4326);
GO

SELECT geometry::STPointFromText('POINT(10 20 NULL NULL)', 2);
GO

SELECT geometry::STPointFromText('POINT EMPTY', 4326);
GO

-- STAsText tests
SELECT geometry::STGeomFromText('POINT(10 20)', 4326).STAsText();
GO

SELECT geometry::STGeomFromText('POINT(10 20 30)', 4326).STAsText();
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL)', 4326).STAsText();
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 1)', 4326).STAsText();
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL 1)', 4326).STAsText();
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 NULL)', 4326).STAsText();
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL NULL)', 4326).STAsText();
GO

SELECT geometry::STGeomFromText('POINT EMPTY', 4326).STAsText();
GO

-- STSrid tests
SELECT geometry::STGeomFromText('POINT(10 20)', 4326).STSrid;
GO

SELECT geometry::STGeomFromText('POINT(10 20 30)', 4326).STSrid;
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL)', 4326).STSrid;
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 1)', 4326).STSrid;
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL 1)', 4326).STSrid;
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 NULL)', 4326).STSrid;
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL NULL)', 4326).STSrid;
GO

SELECT geometry::STGeomFromText('POINT EMPTY', 4326).STSrid;
GO

-- STIsValid tests
SELECT geometry::STGeomFromText('POINT(10 20)', 4326).STIsValid();
GO

SELECT geometry::STGeomFromText('POINT(10 20 30)', 4326).STIsValid();
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL)', 4326).STIsValid();
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 1)', 4326).STIsValid();
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL 1)', 4326).STIsValid();
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 NULL)', 4326).STIsValid();
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL NULL)', 4326).STIsValid();
GO

SELECT geometry::STGeomFromText('POINT EMPTY', 4326).STIsValid();
GO

-- STIsEmpty tests
SELECT geometry::STGeomFromText('POINT(10 20)', 4326).STIsEmpty();
GO

SELECT geometry::STGeomFromText('POINT(10 20 30)', 4326).STIsEmpty();
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL)', 4326).STIsEmpty();
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 1)', 4326).STIsEmpty();
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL 1)', 4326).STIsEmpty();
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 NULL)', 4326).STIsEmpty();
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL NULL)', 4326).STIsEmpty();
GO

SELECT geometry::STGeomFromText('POINT EMPTY', 4326).STIsEmpty();
GO

-- STDimension tests
SELECT geometry::STGeomFromText('POINT(10 20)', 4326).STDimension();
GO

SELECT geometry::STGeomFromText('POINT(10 20 30)', 4326).STDimension();
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL)', 4326).STDimension();
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 1)', 4326).STDimension();
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL 1)', 4326).STDimension();
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 NULL)', 4326).STDimension();
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL NULL)', 4326).STDimension();
GO

SELECT geometry::STGeomFromText('POINT EMPTY', 4326).STDimension();
GO

-- STX, STY tests
SELECT geometry::STGeomFromText('POINT(10 20)', 4326).STX;
GO

SELECT geometry::STGeomFromText('POINT(10 20 30)', 4326).STX;
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL)', 4326).STX;
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 1)', 4326).STX;
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL 1)', 4326).STX;
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 NULL)', 4326).STX;
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL NULL)', 4326).STX;
GO

SELECT geometry::STGeomFromText('POINT EMPTY', 4326).STX;
GO

SELECT geometry::STGeomFromText('POINT(10 20)', 4326).STY;
GO

SELECT geometry::STGeomFromText('POINT(10 20 30)', 4326).STY;
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL)', 4326).STY;
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 1)', 4326).STY;
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL 1)', 4326).STY;
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 NULL)', 4326).STY;
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL NULL)', 4326).STY;
GO

SELECT geometry::STGeomFromText('POINT EMPTY', 4326).STY;
GO

-- STEquals tests
SELECT geometry::STGeomFromText('POINT(10 20)', 4326).STEquals(geometry::STGeomFromText('POINT(10 20)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(10 20 30)', 4326).STEquals(geometry::STGeomFromText('POINT(10 20 30)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL)', 4326).STEquals(geometry::STGeomFromText('POINT(10 20 NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 1)', 4326).STEquals(geometry::STGeomFromText('POINT(10 20 30 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL 1)', 4326).STEquals(geometry::STGeomFromText('POINT(10 20 NULL 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 NULL)', 4326).STEquals(geometry::STGeomFromText('POINT(10 20 30 NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL NULL)', 4326).STEquals(geometry::STGeomFromText('POINT(10 20 NULL NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT EMPTY', 4326).STEquals(geometry::STGeomFromText('POINT EMPTY', 4326));
GO

-- STEquals tests with different dimensions
SELECT geometry::STGeomFromText('POINT(10 20)', 4326).STEquals(geometry::STGeomFromText('POINT(10 20 30)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(10 20)', 4326).STEquals(geometry::STGeomFromText('POINT(10 20 NULL 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(10 20 30)', 4326).STEquals(geometry::STGeomFromText('POINT(10 20 NULL 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(10 20 30)', 4326).STEquals(geometry::STGeomFromText('POINT(10 20 30 NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL)', 4326).STEquals(geometry::STGeomFromText('POINT(10 20 NULL 1)', 4326));
GO

-- STAsBinary tests
SELECT geometry::STGeomFromText('POINT(10 20)', 4326).STAsBinary();
GO

SELECT geometry::STGeomFromText('POINT(10 20 30)', 4326).STAsBinary();
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL)', 4326).STAsBinary();
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 1)', 4326).STAsBinary();
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL 1)', 4326).STAsBinary();
GO

SELECT geometry::STGeomFromText('POINT(10 20 30 NULL)', 4326).STAsBinary();
GO

SELECT geometry::STGeomFromText('POINT(10 20 NULL NULL)', 4326).STAsBinary();
GO

SELECT geometry::STGeomFromText('POINT EMPTY', 4326).STAsBinary();
GO

SELECT geography::STGeomFromText('LINESTRING EMPTY', 4326).STAsBinary();
GO

-- STContains tests
SELECT geometry::STGeomFromText('POINT(1 2)', 4326).STContains(geometry::STGeomFromText('POINT(1 2)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1)', 4326).STContains(geometry::STGeomFromText('POINT(1 2 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL)', 4326).STContains(geometry::STGeomFromText('POINT(1 2 NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1 2)', 4326).STContains(geometry::STGeomFromText('POINT(1 2 1 2)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL 2)', 4326).STContains(geometry::STGeomFromText('POINT(1 2 NULL 2)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1 NULL)', 4326).STContains(geometry::STGeomFromText('POINT(1 2 1 NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL NULL)', 4326).STContains(geometry::STGeomFromText('POINT(1 2 NULL NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT EMPTY', 4326).STContains(geometry::STGeomFromText('POINT EMPTY', 4326));
GO

-- STContains tests with different dimensions
SELECT geometry::STGeomFromText('POINT(1 2)', 4326).STContains(geometry::STGeomFromText('POINT(1 2 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2)', 4326).STContains(geometry::STGeomFromText('POINT(1 2 NULL 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1)', 4326).STContains(geometry::STGeomFromText('POINT(1 2 NULL 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1)', 4326).STContains(geometry::STGeomFromText('POINT(1 2 1 NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL)', 4326).STContains(geometry::STGeomFromText('POINT(1 2 NULL 1)', 4326));
GO

-- STDisjoint tests
SELECT geometry::STGeomFromText('POINT(1 2)', 4326).STDisjoint(geometry::STGeomFromText('POINT(1 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1)', 4326).STDisjoint(geometry::STGeomFromText('POINT(1 1 2)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL)', 4326).STDisjoint(geometry::STGeomFromText('POINT(1 1 NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1 2)', 4326).STDisjoint(geometry::STGeomFromText('POINT(1 1 3 4)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL 2)', 4326).STDisjoint(geometry::STGeomFromText('POINT(1 1 NULL 4)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1 NULL)', 4326).STDisjoint(geometry::STGeomFromText('POINT(1 1 3 NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL NULL)', 4326).STDisjoint(geometry::STGeomFromText('POINT(1 1 NULL NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT EMPTY', 4326).STDisjoint(geometry::STGeomFromText('POINT EMPTY', 4326));
GO

-- STDisjoint tests with different dimensions
SELECT geometry::STGeomFromText('POINT(1 2)', 4326).STDisjoint(geometry::STGeomFromText('POINT(1 1 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2)', 4326).STDisjoint(geometry::STGeomFromText('POINT(1 1 NULL 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1)', 4326).STDisjoint(geometry::STGeomFromText('POINT(1 1 NULL 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1)', 4326).STDisjoint(geometry::STGeomFromText('POINT(1 1 1 NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL)', 4326).STDisjoint(geometry::STGeomFromText('POINT(1 1 NULL 1)', 4326));
GO

-- STIntersects tests
SELECT geometry::STGeomFromText('POINT(1 2)', 4326).STIntersects(geometry::STGeomFromText('POINT(1 2)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1)', 4326).STIntersects(geometry::STGeomFromText('POINT(1 2 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL)', 4326).STIntersects(geometry::STGeomFromText('POINT(1 2 NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1 2)', 4326).STIntersects(geometry::STGeomFromText('POINT(1 2 1 2)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL 2)', 4326).STIntersects(geometry::STGeomFromText('POINT(1 2 NULL 2)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1 NULL)', 4326).STIntersects(geometry::STGeomFromText('POINT(1 2 1 NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL NULL)', 4326).STIntersects(geometry::STGeomFromText('POINT(1 2 NULL NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT EMPTY', 4326).STIntersects(geometry::STGeomFromText('POINT EMPTY', 4326));
GO

-- STIntersects tests with different dimensions
SELECT geometry::STGeomFromText('POINT(1 2)', 4326).STIntersects(geometry::STGeomFromText('POINT(1 2 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2)', 4326).STIntersects(geometry::STGeomFromText('POINT(1 2 NULL 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1)', 4326).STIntersects(geometry::STGeomFromText('POINT(1 2 NULL 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1)', 4326).STIntersects(geometry::STGeomFromText('POINT(1 2 1 NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL)', 4326).STIntersects(geometry::STGeomFromText('POINT(1 2 NULL 1)', 4326));
GO

-- STIsClosed tests
SELECT geometry::STGeomFromText('POINT(1 2)', 4326).STIsClosed();
GO

SELECT geometry::STGeomFromText('POINT(1 2 1)', 4326).STIsClosed();
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL)', 4326).STIsClosed();
GO

SELECT geometry::STGeomFromText('POINT(1 2 1 2)', 4326).STIsClosed();
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL 2)', 4326).STIsClosed();
GO

SELECT geometry::STGeomFromText('POINT(1 2 1 NULL)', 4326).STIsClosed();
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL NULL)', 4326).STIsClosed();
GO

SELECT geometry::STGeomFromText('POINT EMPTY', 4326).STIsClosed();
GO

-- STDistance tests
SELECT geometry::STGeomFromText('POINT(1 2)', 4326).STDistance(geometry::STGeomFromText('POINT(1 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1)', 4326).STDistance(geometry::STGeomFromText('POINT(1 1 2)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL)', 4326).STDistance(geometry::STGeomFromText('POINT(1 1 NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1 2)', 4326).STDistance(geometry::STGeomFromText('POINT(1 1 3 4)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL 2)', 4326).STDistance(geometry::STGeomFromText('POINT(1 1 NULL 4)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1 NULL)', 4326).STDistance(geometry::STGeomFromText('POINT(1 1 3 NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL NULL)', 4326).STDistance(geometry::STGeomFromText('POINT(1 1 NULL NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT EMPTY', 4326).STDistance(geometry::STGeomFromText('POINT EMPTY', 4326));
GO

-- STDistance tests with different dimensions
SELECT geometry::STGeomFromText('POINT(1 2)', 4326).STDistance(geometry::STGeomFromText('POINT(1 1 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2)', 4326).STDistance(geometry::STGeomFromText('POINT(1 1 NULL 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1)', 4326).STDistance(geometry::STGeomFromText('POINT(1 1 NULL 1)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 1)', 4326).STDistance(geometry::STGeomFromText('POINT(1 1 1 NULL)', 4326));
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL)', 4326).STDistance(geometry::STGeomFromText('POINT(1 1 NULL 1)', 4326));
GO

-- STArea tests
SELECT geometry::STGeomFromText('POINT(1 2)', 4326).STArea();
GO

SELECT geometry::STGeomFromText('POINT(1 2 1)', 4326).STArea();
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL)', 4326).STArea();
GO

SELECT geometry::STGeomFromText('POINT(1 2 1 2)', 4326).STArea();
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL 2)', 4326).STArea();
GO

SELECT geometry::STGeomFromText('POINT(1 2 1 NULL)', 4326).STArea();
GO

SELECT geometry::STGeomFromText('POINT(1 2 NULL NULL)', 4326).STArea();
GO

SELECT geometry::STGeomFromText('POINT EMPTY', 4326).STArea();
GO

-- Test CAST (text AS GEOMETRY)
SELECT CAST(geometry::STGeomFromText('POINT(1 2)', 0) AS VARBINARY(100));
GO
SELECT CAST(geometry::STGeomFromText('POINT(1 2 10)', 0) AS VARBINARY(100));
GO
SELECT CAST(geometry::STGeomFromText('POINT(1 2 NULL 1)', 0) AS VARBINARY(100));
GO
SELECT CAST(geometry::STGeomFromText('POINT(1 2 10 1)', 0) AS VARBINARY(100));
GO
SELECT CAST(geometry::STGeomFromText('POINT EMPTY', 0) AS VARBINARY(100));
GO
SELECT CAST(geometry::STGeomFromText(NULL, 0) AS VARBINARY(100));
GO

-- Test CAST (GEOMETRY AS text)
SELECT CAST(geometry::STGeomFromText('POINT(1 2)', 0) AS VARCHAR(100));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geometry::STGeomFromText('POINT(1 2 10)', 0) AS VARCHAR(100));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geometry::STGeomFromText('POINT(1 2 NULL 1)', 0) AS VARCHAR(100));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geometry::STGeomFromText('POINT(1 2 10 1)', 0) AS VARCHAR(100));
GO

SELECT CAST(geometry::STGeomFromText('POINT EMPTY', 0) AS VARCHAR(100));
GO

SELECT CAST(geometry::STGeomFromText(NULL, 0) AS VARCHAR(100));
GO

-- Test CAST (CHAR AS GEOMETRY)
SELECT CAST(geometry::STGeomFromText(CAST('POINT(1 2)' AS CHAR(20)), 0) AS VARBINARY(100));
GO

SELECT CAST(geometry::STGeomFromText(CAST('POINT(1 2 10)' AS CHAR(30)), 0) AS VARBINARY(100));
GO

SELECT CAST(geometry::STGeomFromText(CAST('POINT(1 2 NULL 1)' AS CHAR(30)), 0) AS VARBINARY(100));
GO

SELECT CAST(geometry::STGeomFromText(CAST('POINT(1 2 10 1)' AS CHAR(40)), 0) AS VARBINARY(100));
GO

SELECT CAST(geometry::STGeomFromText(CAST('POINT EMPTY' AS CHAR(20)), 0) AS VARBINARY(100));
GO

SELECT CAST(geometry::STGeomFromText(CAST(NULL AS CHAR(20)), 0) AS VARBINARY(100));
GO

-- Test CAST (GEOMETRY AS CHAR)
SELECT CAST(geometry::STGeomFromText('POINT(1 2)', 0) AS CHAR(50));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geometry::STGeomFromText('POINT(1 2 10)', 0) AS CHAR(50));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geometry::STGeomFromText('POINT(1 2 NULL 1)', 0) AS CHAR(50));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geometry::STGeomFromText('POINT(1 2 10 1)', 0) AS CHAR(50));
GO

SELECT CAST(geometry::STGeomFromText('POINT EMPTY', 0) AS CHAR(50));
GO

SELECT CAST(geometry::STGeomFromText(NULL, 0) AS CHAR(50));
GO

-- Test CAST (VARCHAR AS GEOMETRY)
SELECT CAST(geometry::STGeomFromText(CAST('POINT(1 2)' AS VARCHAR(20)), 0) AS VARBINARY(100));
GO

SELECT CAST(geometry::STGeomFromText(CAST('POINT(1 2 10)' AS VARCHAR(30)), 0) AS VARBINARY(100));
GO

SELECT CAST(geometry::STGeomFromText(CAST('POINT(1 2 NULL 1)' AS VARCHAR(30)), 0) AS VARBINARY(100));
GO

SELECT CAST(geometry::STGeomFromText(CAST('POINT(1 2 10 1)' AS VARCHAR(40)), 0) AS VARBINARY(100));
GO

SELECT CAST(geometry::STGeomFromText(CAST('POINT EMPTY' AS VARCHAR(20)), 0) AS VARBINARY(100));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geometry::STGeomFromText(CAST(NULL AS VARCHAR(20)), 0) AS VARBINARY(100));
GO

-- Test CAST (GEOMETRY AS VARCHAR)
SELECT CAST(geometry::STGeomFromText('POINT(1 2)', 0) AS VARCHAR(100));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geometry::STGeomFromText('POINT(1 2 10)', 0) AS VARCHAR(100));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geometry::STGeomFromText('POINT(1 2 NULL 1)', 0) AS VARCHAR(100));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geometry::STGeomFromText('POINT(1 2 10 1)', 0) AS VARCHAR(100));
GO

SELECT CAST(geometry::STGeomFromText('POINT EMPTY', 0) AS VARCHAR(100));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geometry::STGeomFromText(NULL, 0) AS VARCHAR(100));
GO

-- Test CAST (GEOMETRY AS VARBINARY)
SELECT CAST(geometry::STGeomFromText('POINT(1 2)', 0) AS VARBINARY(100));
GO

SELECT CAST(geometry::STGeomFromText('POINT(1 2 10)', 4326) AS VARBINARY(100));
GO

SELECT CAST(geometry::STGeomFromText('POINT(1 2 NULL 1)', 0) AS VARBINARY(100));
GO

SELECT CAST(geometry::STGeomFromText('POINT(1 2 10 1)', 0) AS VARBINARY(100));
GO

SELECT CAST(geometry::STGeomFromText('POINT EMPTY', 0) AS VARBINARY(100));
GO

SELECT CAST(geometry::STGeomFromText(NULL, 0) AS VARBINARY(100));
GO

SELECT CAST(CAST(geometry::STGeomFromText('POINT(10 20 30 NULL)', 4326) AS VARBINARY(100)) AS geometry);
GO

SELECT CAST(CAST(geometry::STGeomFromText('POINT(10 20 NULL NULL)', 4326) AS VARBINARY(100)) AS geometry);
GO

SELECT CAST(CAST(geometry::STGeomFromText('POINT(10 20 30 40)', 4326) AS VARBINARY(100)) AS geometry);
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(CAST(geometry::STGeomFromText('POINT EMPTY', 4326) AS VARBINARY(100)) AS geometry);
GO

-- chartogeom

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST('POINT(10 20 30 NULL)' AS geometry).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST('POINT(10 20 NULL NULL)' AS geometry).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST('POINT(10 20 30 40)' AS geometry).STAsText();
GO

SELECT CAST('POINT EMPTY' AS geometry).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(CAST('POINT(10 20 30 NULL)' AS VARCHAR(100)) AS geometry).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(CAST('POINT(10 20 NULL NULL)' AS VARCHAR(100)) AS geometry).STAsText();
GO

SELECT CAST(CAST('POINT(10 20 30 40)' AS VARCHAR(100)) AS geometry).STAsText();
GO

SELECT CAST(CAST('POINT EMPTY' AS VARCHAR(100)) AS geometry).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(CAST(geometry::STGeomFromText('POINT(10 20 30 NULL)', 4326) AS VARCHAR(100)) AS geometry).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(CAST(geometry::STGeomFromText('POINT(10 20 NULL NULL)', 4326) AS VARCHAR(100)) AS geometry).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(CAST(geometry::STGeomFromText('POINT(10 20 30 40)', 4326) AS VARCHAR(100)) AS geometry).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(CAST(geometry::STGeomFromText('POINT EMPTY', 4326) AS VARCHAR(100)) AS geometry).STAsText();
GO

-- ST_Zmflag tests
SELECT sys.ST_Zmflag(geometry::STGeomFromText('POINT(10 20)', 4326));
GO

SELECT sys.ST_Zmflag(geometry::STGeomFromText('POINT(10 20 30)', 4326));
GO

SELECT sys.ST_Zmflag(geometry::STGeomFromText('POINT(10 20 NULL)', 4326));
GO

SELECT sys.ST_Zmflag(geometry::STGeomFromText('POINT(10 20 30 1)', 4326));
GO

SELECT sys.ST_Zmflag(geometry::STGeomFromText('POINT(10 20 NULL 1)', 4326));
GO

SELECT sys.ST_Zmflag(geometry::STGeomFromText('POINT(10 20 30 NULL)', 4326));
GO

SELECT sys.ST_Zmflag(geometry::STGeomFromText('POINT(10 20 NULL NULL)', 4326));
GO

SELECT sys.ST_Zmflag(geometry::STGeomFromText('POINT EMPTY', 4326));
GO

-- Additional tests for edge cases

-- Test with zero values
SELECT geometry::STGeomFromText('POINT(1 2)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(1 2 0)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(1 2 1 2)', 4326);
GO

-- Test with negative values
SELECT geometry::STGeomFromText('POINT(-1 -1)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(-1 -1 -1)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(-1 -1 -1 -1)', 4326);
GO

-- Test with mixed positive and negative values
SELECT geometry::STGeomFromText('POINT(1 -1 1 -1)', 4326);
GO

-- Test with different SRID values
SELECT geometry::STGeomFromText('POINT(1 1)', 0);
GO

SELECT geometry::STGeomFromText('POINT(1 1)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(1 1)', 3857);
GO

-- Test invalid SRID values (these should raise errors)
SELECT geometry::STGeomFromText('POINT(1 1)', -1);
GO

SELECT geometry::STGeomFromText('POINT(1 1)', 1000000);
GO

-- Test with extra whitespace
SELECT geometry::STGeomFromText('  POINT  (  1  1  )  ', 4326);
GO

-- Test case sensitivity
SELECT geometry::STGeomFromText('point(1 1)', 4326);
GO

SELECT geometry::STGeomFromText('Point (1 1 1)', 4326);
GO

-- Test invalid WKT (these should raise errors)
SELECT geometry::STGeomFromText('POINT(1)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(1 2 3 4 5)', 4326);
GO

SELECT geometry::STGeomFromText('POINT(1,2)', 4326);
GO

-- Test with NULL inputs
SELECT geometry::STGeomFromText(NULL, 4326);
GO

SELECT geometry::STGeomFromText('POINT(1 1)', NULL);
GO

-- Test with very long coordinate strings
SELECT geometry::STGeomFromText('POINT(' + REPLICATE('1', 1000) + ' ' + REPLICATE('2', 1000) + ')', 4326);
GO
