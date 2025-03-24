
-- STGeomFromText tests
SELECT geography::STGeomFromText('POINT(10 20)', 4326) ;
GO
  
SELECT geography::STGeomFromText('POINT(10 20 30)', 4121);
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL)', 104001);
GO

SELECT geography::STGeomFromText('POINT(10 20 30 1)', 4981); 
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL 1)', 4983);
GO

SELECT geography::STGeomFromText('POINT(10 20 30 NULL)', 4985);
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL NULL)', 4326);
GO

SELECT geography::STGeomFromText('POINT EMPTY', 4326);  
GO

-- STPointFromText tests
SELECT geography::STPointFromText('POINT(10 20)', 4326);
GO

SELECT geography::STPointFromText('POINT(10 20 30)', 4326);
GO

SELECT geography::STPointFromText('POINT(10 20 NULL)', 4326);
GO

SELECT geography::STPointFromText('POINT(10 20 30 1)', 4326);
GO

SELECT geography::STPointFromText('POINT(10 20 NULL 1)', 4326);
GO

SELECT geography::STPointFromText('POINT(10 20 30 NULL)', 4326);
GO

SELECT geography::STPointFromText('POINT(10 20 NULL NULL)', 4326);
GO

SELECT geography::STPointFromText('POINT EMPTY', 4326);
GO

-- STAsText tests
SELECT geography::STGeomFromText('POINT(10 20)', 4326).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT geography::STGeomFromText('POINT(10 20 30)', 4326).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT geography::STGeomFromText('POINT(10 20 30)', 4326).STAsText();
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL)', 4326).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT geography::STGeomFromText('POINT(10 20 30 1)', 4326).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT geography::STGeomFromText('POINT(10 20 NULL 1)', 4326).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT geography::STGeomFromText('POINT(10 20 30 NULL)', 4326).STAsText();
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL NULL)', 4326).STAsText();
GO

SELECT geography::STGeomFromText('POINT EMPTY', 4326).STAsText();
GO

-- STSrid tests
SELECT geography::STGeomFromText('POINT(10 20)', 4326).STSrid;
GO

SELECT geography::STGeomFromText('POINT(10 20 30)', 4326).STSrid;
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL)', 4326).STSrid;
GO

SELECT geography::STGeomFromText('POINT(10 20 30 1)', 4326).STSrid;
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL 1)', 4326).STSrid;
GO

SELECT geography::STGeomFromText('POINT(10 20 30 NULL)', 4326).STSrid;
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL NULL)', 4326).STSrid;
GO

SELECT geography::STGeomFromText('POINT EMPTY', 4326).STSrid;
GO

-- STIsValid tests
SELECT geography::STGeomFromText('POINT(10 20)', 4326).STIsValid();
GO

SELECT geography::STGeomFromText('POINT(10 20 30)', 4326).STIsValid();
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL)', 4326).STIsValid();
GO

SELECT geography::STGeomFromText('POINT(10 20 30 1)', 4326).STIsValid();
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL 1)', 4326).STIsValid();
GO

SELECT geography::STGeomFromText('POINT(10 20 30 NULL)', 4326).STIsValid();
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL NULL)', 4326).STIsValid();
GO

SELECT geography::STGeomFromText('POINT EMPTY', 4326).STIsValid();
GO

-- STIsEmpty tests
SELECT geography::STGeomFromText('POINT(10 20)', 4326).STIsEmpty();
GO

SELECT geography::STGeomFromText('POINT(10 20 30)', 4326).STIsEmpty();
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL)', 4326).STIsEmpty();
GO

SELECT geography::STGeomFromText('POINT(10 20 30 1)', 4326).STIsEmpty();
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL 1)', 4326).STIsEmpty();
GO

SELECT geography::STGeomFromText('POINT(10 20 30 NULL)', 4326).STIsEmpty();
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL NULL)', 4326).STIsEmpty();
GO

SELECT geography::STGeomFromText('POINT EMPTY', 4326).STIsEmpty();
GO

-- STDimension tests
SELECT geography::STGeomFromText('POINT(10 20)', 4326).STDimension();
GO

SELECT geography::STGeomFromText('POINT(10 20 30)', 4326).STDimension();
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL)', 4326).STDimension();
GO

SELECT geography::STGeomFromText('POINT(10 20 30 1)', 4326).STDimension();
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL 1)', 4326).STDimension();
GO

SELECT geography::STGeomFromText('POINT(10 20 30 NULL)', 4326).STDimension();
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL NULL)', 4326).STDimension();
GO

SELECT geography::STGeomFromText('POINT EMPTY', 4326).STDimension();
GO

-- Lat, Long tests
SELECT geography::STGeomFromText('POINT(10 20)', 4326).Lat;
GO

SELECT geography::STGeomFromText('POINT(10 20 30)', 4326).Lat;
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL)', 4326).Lat;
GO

SELECT geography::STGeomFromText('POINT(10 20 30 1)', 4326).Lat;
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL 1)', 4326).Lat;
GO

SELECT geography::STGeomFromText('POINT(10 20 30 NULL)', 4326).Lat;
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL NULL)', 4326).Lat;
GO

SELECT geography::STGeomFromText('POINT EMPTY', 4326).Lat;
GO

SELECT geography::STGeomFromText('POINT(10 20)', 4326).Long;
GO

SELECT geography::STGeomFromText('POINT(10 20 30)', 4326).Long;
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL)', 4326).Long;
GO

SELECT geography::STGeomFromText('POINT(10 20 30 1)', 4326).Long;
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL 1)', 4326).Long;
GO

SELECT geography::STGeomFromText('POINT(10 20 30 NULL)', 4326).Long;
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL NULL)', 4326).Long;
GO

SELECT geography::STGeomFromText('POINT EMPTY', 4326).Long;
GO

-- STEquals tests
SELECT geography::STGeomFromText('POINT(10 20)', 4326).STEquals(geography::STGeomFromText('POINT(10 20)', 4326));
GO

SELECT geography::STGeomFromText('POINT(10 20 30)', 4326).STEquals(geography::STGeomFromText('POINT(10 20 30)', 4326));
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL)', 4326).STEquals(geography::STGeomFromText('POINT(10 20 NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT(10 20 30 1)', 4326).STEquals(geography::STGeomFromText('POINT(10 20 30 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL 1)', 4326).STEquals(geography::STGeomFromText('POINT(10 20 NULL 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(10 20 30 NULL)', 4326).STEquals(geography::STGeomFromText('POINT(10 20 30 NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL NULL)', 4326).STEquals(geography::STGeomFromText('POINT(10 20 NULL NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT EMPTY', 4326).STEquals(geography::STGeomFromText('POINT EMPTY', 4326));
GO

-- STEquals tests with different dimensions
SELECT geography::STGeomFromText('POINT(10 20)', 4326).STEquals(geography::STGeomFromText('POINT(10 20 30)', 4326));
GO

SELECT geography::STGeomFromText('POINT(10 20)', 4326).STEquals(geography::STGeomFromText('POINT(10 20 NULL 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(10 20 30)', 4326).STEquals(geography::STGeomFromText('POINT(10 20 NULL 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(10 20 30)', 4326).STEquals(geography::STGeomFromText('POINT(10 20 30 NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL)', 4326).STEquals(geography::STGeomFromText('POINT(10 20 NULL 1)', 4326));
GO

-- STAsBinary tests
SELECT geography::STGeomFromText('POINT(10 20)', 4326).STAsBinary();
GO

SELECT geography::STGeomFromText('POINT(10 20 30)', 4326).STAsBinary();
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL)', 4326).STAsBinary();
GO

SELECT geography::STGeomFromText('POINT(10 20 30 1)', 4326).STAsBinary();
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL 1)', 4326).STAsBinary();
GO

SELECT geography::STGeomFromText('POINT(10 20 30 NULL)', 4326).STAsBinary();
GO

SELECT geography::STGeomFromText('POINT(10 20 NULL NULL)', 4326).STAsBinary();
GO

SELECT geography::STGeomFromText('POINT EMPTY', 4326).STAsBinary();
GO

-- STContains tests
SELECT geography::STGeomFromText('POINT(1 2)', 4326).STContains(geography::STGeomFromText('POINT(1 2)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1)', 4326).STContains(geography::STGeomFromText('POINT(1 2 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL)', 4326).STContains(geography::STGeomFromText('POINT(1 2 NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1 2)', 4326).STContains(geography::STGeomFromText('POINT(1 2 1 2)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL 2)', 4326).STContains(geography::STGeomFromText('POINT(1 2 NULL 2)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1 NULL)', 4326).STContains(geography::STGeomFromText('POINT(1 2 1 NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL NULL)', 4326).STContains(geography::STGeomFromText('POINT(1 2 NULL NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT EMPTY', 4326).STContains(geography::STGeomFromText('POINT EMPTY', 4326));
GO

-- STContains tests with different dimensions
SELECT geography::STGeomFromText('POINT(1 2)', 4326).STContains(geography::STGeomFromText('POINT(1 2 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2)', 4326).STContains(geography::STGeomFromText('POINT(1 2 NULL 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1)', 4326).STContains(geography::STGeomFromText('POINT(1 2 NULL 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1)', 4326).STContains(geography::STGeomFromText('POINT(1 2 1 NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL)', 4326).STContains(geography::STGeomFromText('POINT(1 2 NULL 1)', 4326));
GO

-- STDisjoint tests
SELECT geography::STGeomFromText('POINT(1 2)', 4326).STDisjoint(geography::STGeomFromText('POINT(1 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1)', 4326).STDisjoint(geography::STGeomFromText('POINT(1 1 2)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL)', 4326).STDisjoint(geography::STGeomFromText('POINT(1 1 NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1 2)', 4326).STDisjoint(geography::STGeomFromText('POINT(1 1 3 4)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL 2)', 4326).STDisjoint(geography::STGeomFromText('POINT(1 1 NULL 4)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1 NULL)', 4326).STDisjoint(geography::STGeomFromText('POINT(1 1 3 NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL NULL)', 4326).STDisjoint(geography::STGeomFromText('POINT(1 1 NULL NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT EMPTY', 4326).STDisjoint(geography::STGeomFromText('POINT EMPTY', 4326));
GO

-- STDisjoint tests with different dimensions
SELECT geography::STGeomFromText('POINT(1 2)', 4326).STDisjoint(geography::STGeomFromText('POINT(1 1 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2)', 4326).STDisjoint(geography::STGeomFromText('POINT(1 1 NULL 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1)', 4326).STDisjoint(geography::STGeomFromText('POINT(1 1 NULL 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1)', 4326).STDisjoint(geography::STGeomFromText('POINT(1 1 1 NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL)', 4326).STDisjoint(geography::STGeomFromText('POINT(1 1 NULL 1)', 4326));
GO

-- STIntersects tests
SELECT geography::STGeomFromText('POINT(1 2)', 4326).STIntersects(geography::STGeomFromText('POINT(1 2)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1)', 4326).STIntersects(geography::STGeomFromText('POINT(1 2 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL)', 4326).STIntersects(geography::STGeomFromText('POINT(1 2 NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1 2)', 4326).STIntersects(geography::STGeomFromText('POINT(1 2 1 2)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL 2)', 4326).STIntersects(geography::STGeomFromText('POINT(1 2 NULL 2)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1 NULL)', 4326).STIntersects(geography::STGeomFromText('POINT(1 2 1 NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL NULL)', 4326).STIntersects(geography::STGeomFromText('POINT(1 2 NULL NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT EMPTY', 4326).STIntersects(geography::STGeomFromText('POINT EMPTY', 4326));
GO

-- STIntersects tests with different dimensions
SELECT geography::STGeomFromText('POINT(1 2)', 4326).STIntersects(geography::STGeomFromText('POINT(1 2 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2)', 4326).STIntersects(geography::STGeomFromText('POINT(1 2 NULL 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1)', 4326).STIntersects(geography::STGeomFromText('POINT(1 2 NULL 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1)', 4326).STIntersects(geography::STGeomFromText('POINT(1 2 1 NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL)', 4326).STIntersects(geography::STGeomFromText('POINT(1 2 NULL 1)', 4326));
GO

-- STIsClosed tests
SELECT geography::STGeomFromText('POINT(1 2)', 4326).STIsClosed();
GO

SELECT geography::STGeomFromText('POINT(1 2 1)', 4326).STIsClosed();
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL)', 4326).STIsClosed();
GO

SELECT geography::STGeomFromText('POINT(1 2 1 2)', 4326).STIsClosed();
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL 2)', 4326).STIsClosed();
GO

SELECT geography::STGeomFromText('POINT(1 2 1 NULL)', 4326).STIsClosed();
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL NULL)', 4326).STIsClosed();
GO

SELECT geography::STGeomFromText('POINT EMPTY', 4326).STIsClosed();
GO

-- STDistance tests
SELECT geography::STGeomFromText('POINT(1 2)', 4326).STDistance(geography::STGeomFromText('POINT(1 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1)', 4326).STDistance(geography::STGeomFromText('POINT(1 1 2)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL)', 4326).STDistance(geography::STGeomFromText('POINT(1 1 NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1 2)', 4326).STDistance(geography::STGeomFromText('POINT(1 1 3 4)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL 2)', 4326).STDistance(geography::STGeomFromText('POINT(1 1 NULL 4)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1 NULL)', 4326).STDistance(geography::STGeomFromText('POINT(1 1 3 NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL NULL)', 4326).STDistance(geography::STGeomFromText('POINT(1 1 NULL NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT EMPTY', 4326).STDistance(geography::STGeomFromText('POINT EMPTY', 4326));
GO

-- STDistance tests with different dimensions
SELECT geography::STGeomFromText('POINT(1 2)', 4326).STDistance(geography::STGeomFromText('POINT(1 1 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2)', 4326).STDistance(geography::STGeomFromText('POINT(1 1 NULL 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1)', 4326).STDistance(geography::STGeomFromText('POINT(1 1 NULL 1)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 1)', 4326).STDistance(geography::STGeomFromText('POINT(1 1 1 NULL)', 4326));
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL)', 4326).STDistance(geography::STGeomFromText('POINT(1 1 NULL 1)', 4326));
GO

-- STArea tests
SELECT geography::STGeomFromText('POINT(1 2)', 4326).STArea();
GO

SELECT geography::STGeomFromText('POINT(1 2 1)', 4326).STArea();
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL)', 4326).STArea();
GO

SELECT geography::STGeomFromText('POINT(1 2 1 2)', 4326).STArea();
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL 2)', 4326).STArea();
GO

SELECT geography::STGeomFromText('POINT(1 2 1 NULL)', 4326).STArea();
GO

SELECT geography::STGeomFromText('POINT(1 2 NULL NULL)', 4326).STArea();
GO

SELECT geography::STGeomFromText('POINT EMPTY', 4326).STArea();
GO

-- Test CAST (text AS geography)
SELECT CAST(geography::STGeomFromText('POINT(1 2)', 4326) AS VARBINARY(100));
GO

SELECT CAST(geography::STGeomFromText('POINT(1 2 10)', 4326) AS VARBINARY(100));
GO

SELECT CAST(geography::STGeomFromText('POINT(1 2 NULL 1)', 4326) AS VARBINARY(100));
GO

SELECT CAST(geography::STGeomFromText('POINT(1 2 10 1)', 4326) AS VARBINARY(100));
GO

SELECT CAST(geography::STGeomFromText('POINT EMPTY', 4326) AS VARBINARY(100));
GO

SELECT CAST(geography::STGeomFromText(NULL, 4326) AS VARBINARY(100));
GO

-- Test CAST (geography AS text)
SELECT CAST(geography::STGeomFromText('POINT(1 2)', 4326) AS VARCHAR(100));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geography::STGeomFromText('POINT(1 2 10)', 4326) AS VARCHAR(100));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geography::STGeomFromText('POINT(1 2 NULL 1)', 4326) AS VARCHAR(100));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geography::STGeomFromText('POINT(1 2 10 1)', 4326) AS VARCHAR(100));
GO

SELECT CAST(geography::STGeomFromText('POINT EMPTY', 4326) AS VARCHAR(100));
GO

SELECT CAST(geography::STGeomFromText(NULL, 4326) AS VARCHAR(100));
GO

-- Test CAST (CHAR AS geography)
SELECT CAST(geography::STGeomFromText(CAST('POINT(1 2)' AS CHAR(20)), 4326) AS VARBINARY(100));
GO

SELECT CAST(geography::STGeomFromText(CAST('POINT(1 2 10)' AS CHAR(30)), 4326) AS VARBINARY(100));
GO

SELECT CAST(geography::STGeomFromText(CAST('POINT(1 2 NULL 1)' AS CHAR(30)), 4326) AS VARBINARY(100));
GO

SELECT CAST(geography::STGeomFromText(CAST('POINT(1 2 10 1)' AS CHAR(40)), 4326) AS VARBINARY(100));
GO

SELECT CAST(geography::STGeomFromText(CAST('POINT EMPTY' AS CHAR(20)), 4326) AS VARBINARY(100));
GO

SELECT CAST(geography::STGeomFromText(CAST(NULL AS CHAR(20)), 4326) AS VARBINARY(100));
GO

-- Test CAST (geography AS CHAR)
SELECT CAST(geography::STGeomFromText('POINT(1 2)', 4326) AS CHAR(50));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geography::STGeomFromText('POINT(1 2 10)', 4326) AS CHAR(50));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geography::STGeomFromText('POINT(1 2 NULL 1)', 4326) AS CHAR(50));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geography::STGeomFromText('POINT(1 2 10 1)', 4326) AS CHAR(50));
GO

SELECT CAST(geography::STGeomFromText('POINT EMPTY', 4326) AS CHAR(50));
GO

SELECT CAST(geography::STGeomFromText(NULL, 4326) AS CHAR(50));
GO

-- Test CAST (VARCHAR AS geography)
SELECT CAST(geography::STGeomFromText(CAST('POINT(1 2)' AS VARCHAR(20)), 4326) AS VARBINARY(100));
GO

SELECT CAST(geography::STGeomFromText(CAST('POINT(1 2 10)' AS VARCHAR(30)), 4326) AS VARBINARY(100));
GO

SELECT CAST(geography::STGeomFromText(CAST('POINT(1 2 NULL 1)' AS VARCHAR(30)), 4326) AS VARBINARY(100));
GO

SELECT CAST(geography::STGeomFromText(CAST('POINT(1 2 10 1)' AS VARCHAR(40)), 4326) AS VARBINARY(100));
GO

SELECT CAST(geography::STGeomFromText(CAST('POINT EMPTY' AS VARCHAR(20)), 4326) AS VARBINARY(100));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geography::STGeomFromText(CAST(NULL AS VARCHAR(20)), 4326) AS VARBINARY(100));
GO

-- Test CAST (geography AS VARCHAR)
SELECT CAST(geography::STGeomFromText('POINT(1 2)', 4326) AS VARCHAR(100));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geography::STGeomFromText('POINT(1 2 10)', 4326) AS VARCHAR(100));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geography::STGeomFromText('POINT(1 2 NULL 1)', 4326) AS VARCHAR(100));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geography::STGeomFromText('POINT(1 2 10 1)', 4326) AS VARCHAR(100));
GO

SELECT CAST(geography::STGeomFromText('POINT EMPTY', 4326) AS VARCHAR(100));
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(geography::STGeomFromText(NULL, 4326) AS VARCHAR(100));
GO

-- Test CAST (geography AS VARBINARY)
SELECT CAST(geography::STGeomFromText('POINT(1 2)', 4326) AS VARBINARY(100));
GO

SELECT CAST(geography::STGeomFromText('POINT(1 2 10)', 4326) AS VARBINARY(100));
GO

SELECT CAST(geography::STGeomFromText('POINT(1 2 NULL 1)', 4326) AS VARBINARY(100));
GO

SELECT CAST(geography::STGeomFromText('POINT(1 2 10 1)', 4326) AS VARBINARY(100));
GO

--TODO: Fix this test
SELECT CAST(geography::STGeomFromText('POINT EMPTY', 4326) AS VARBINARY(100));
GO
SELECT CAST(geography::STGeomFromText(NULL, 4326) AS VARBINARY(100));
GO

SELECT CAST(CAST(geography::STGeomFromText('POINT(10 20 30 NULL)', 4326) AS VARBINARY(100)) AS geography);
GO

SELECT CAST(CAST(geography::STGeomFromText('POINT(10 20 NULL NULL)', 4326) AS VARBINARY(100)) AS geography);
GO

SELECT CAST(CAST(geography::STGeomFromText('POINT(10 20 30 40)', 4326) AS VARBINARY(100)) AS geography);
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(CAST(geography::STGeomFromText('POINT EMPTY', 4326) AS VARBINARY(100)) AS geography);
GO

-- chartogeom

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST('POINT(10 20 30 NULL)' AS geography).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST('POINT(10 20 NULL NULL)' AS geography).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST('POINT(10 20 30 40)' AS geography).STAsText();
GO

SELECT CAST('POINT EMPTY' AS geography).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(CAST('POINT(10 20 30 NULL)' AS VARCHAR(100)) AS geography).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(CAST('POINT(10 20 NULL NULL)' AS VARCHAR(100)) AS geography).STAsText();
GO

SELECT CAST(CAST('POINT(10 20 30 40)' AS VARCHAR(100)) AS geography).STAsText();
GO

SELECT CAST(CAST('POINT EMPTY' AS VARCHAR(100)) AS geography).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(CAST(geography::STGeomFromText('POINT(10 20 30 NULL)', 4326) AS VARCHAR(100)) AS geography).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(CAST(geography::STGeomFromText('POINT(10 20 NULL NULL)', 4326) AS VARCHAR(100)) AS geography).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(CAST(geography::STGeomFromText('POINT(10 20 30 40)', 4326) AS VARCHAR(100)) AS geography).STAsText();
GO

-- TODO: This test will be updated later to match T-SQL output
SELECT CAST(CAST(geography::STGeomFromText('POINT EMPTY', 4326) AS VARCHAR(100)) AS geography).STAsText();
GO

-- ST_Zmflag tests
SELECT sys.ST_Zmflag(geography::STGeomFromText('POINT(10 20)', 4326));
GO

SELECT sys.ST_Zmflag(geography::STGeomFromText('POINT(10 20 30)', 4326));
GO

SELECT sys.ST_Zmflag(geography::STGeomFromText('POINT(10 20 NULL)', 4326));
GO

SELECT sys.ST_Zmflag(geography::STGeomFromText('POINT(10 20 30 1)', 4326));
GO

SELECT sys.ST_Zmflag(geography::STGeomFromText('POINT(10 20 NULL 1)', 4326));
GO

SELECT sys.ST_Zmflag(geography::STGeomFromText('POINT(10 20 30 NULL)', 4326));
GO

SELECT sys.ST_Zmflag(geography::STGeomFromText('POINT(10 20 NULL NULL)', 4326));
GO

SELECT sys.ST_Zmflag(geography::STGeomFromText('POINT EMPTY', 4326));
GO

-- Additional tests for edge cases

-- Test with zero values
SELECT geography::STGeomFromText('POINT(1 2)', 4326);
GO

SELECT geography::STGeomFromText('POINT(1 2 0)', 4326);
GO

SELECT geography::STGeomFromText('POINT(1 2 1 2)', 4326);
GO

-- Test with negative values
SELECT geography::STGeomFromText('POINT(-1 -1)', 4326);
GO

SELECT geography::STGeomFromText('POINT(-1 -1 -1)', 4326);
GO

SELECT geography::STGeomFromText('POINT(-1 -1 -1 -1)', 4326);
GO

-- Test with mixed positive and negative values
SELECT geography::STGeomFromText('POINT(1 -1 1 -1)', 4326);
GO

-- Test with different SRID values

SELECT geography::STGeomFromText('POINT(1 1)', 4326);
GO

SELECT geography::STGeomFromText('POINT(1 1)', 4121);
GO

-- Test invalid SRID values (these should raise errors)
SELECT geography::STGeomFromText('POINT(1 1)', -1);
GO

SELECT geography::STGeomFromText('POINT(1 1)', 1000000);
GO

SELECT geography::STGeomFromText('POINT(1 1)', 0);
GO

-- Test with extra whitespace
SELECT geography::STGeomFromText('  POINT  (  1  1  )  ', 4326);
GO

-- Test case sensitivity
SELECT geography::STGeomFromText('point(1 1)', 4326);
GO

SELECT geography::STGeomFromText('Point (1 1 1)', 4326);
GO

-- Test invalid WKT (these should raise errors)
SELECT geography::STGeomFromText('POINT(1)', 4326);
GO

SELECT geography::STGeomFromText('POINT(1 2 3 4 5)', 4326);
GO

SELECT geography::STGeomFromText('POINT(1,2)', 4326);
GO

-- Test with NULL inputs
SELECT geography::STGeomFromText(NULL, 4326);
GO

SELECT geography::STGeomFromText('POINT(1 1)', NULL);
GO

-- Test with very long coordinate strings
SELECT geography::STGeomFromText('POINT(' + REPLICATE('1', 1000) + ' ' + REPLICATE('2', 1000) + ')', 4326);
GO

-- ST_Transform tests
SELECT sys.STAsText(sys.ST_Transform(geography::STGeomFromText('POINT(1 2)', 4326), 4269));
GO

SELECT sys.STAsText(sys.ST_Transform(geography::STGeomFromText('POINT(180 90)', 4326), 4269));
GO

SELECT sys.STAsText(sys.ST_Transform(geography::STGeomFromText('POINT(-180 -90)', 4326), 4269));
GO

SELECT sys.STAsText(sys.ST_Transform(geography::STGeomFromText('POINT(1 2 10)', 4326), 4269));    -- 3D point
GO

SELECT sys.ST_Transform(geography::STGeomFromText('POINT(1 2)', 4326), 3857);    -- Should raise an error (invalid SRID for geography)
GO

-- Geography__STFlipCoordinates tests
SELECT sys.STAsText(sys.Geography__STFlipCoordinates(geography::STGeomFromText('POINT(45 90)', 4326)));
GO

SELECT sys.STAsText(sys.Geography__STFlipCoordinates(geography::STGeomFromText('POINT(-180 -90)', 4326)));
GO

SELECT sys.STAsText(sys.Geography__STFlipCoordinates(geography::STGeomFromText('POINT(180 90)', 4326)));
GO

SELECT sys.STAsText(sys.Geography__STFlipCoordinates(geography::STGeomFromText('POINT(1 2 10)', 4326)));    -- 3D point
GO

SELECT sys.STAsText(sys.Geography__STFlipCoordinates(geography::STGeomFromText('POINT(45 90 10 1)', 4326)));    -- 4D point
GO

SELECT sys.STAsText(sys.Geography__STFlipCoordinates(geography::STGeomFromText('POINT EMPTY', 4326)));
GO

-- Test with extreme coordinate values
SELECT geography::STGeomFromText('POINT(180 90)', 4326);  SELECT geography::STGeomFromText('POINT(-180 -90)', 4326);  
GO

SELECT geography::STGeomFromText('POINT(180 90 100)', 4326);  SELECT geography::STGeomFromText('POINT(-180 -90 -100)', 4326);
GO

SELECT geography::STGeomFromText('POINT(180 90 100 200)', 4326);  SELECT geography::STGeomFromText('POINT(-180 -90 -100 -200)', 4326);
GO

-- Test with very small coordinate values
SELECT geography::STGeomFromText('POINT(0.0000001 0.0000001)', 4326);  
GO
