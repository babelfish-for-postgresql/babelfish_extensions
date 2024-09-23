-- BABEL-4912 test ALTER TABLE for temp tables
CREATE TABLE #t1 (a INT IDENTITY PRIMARY KEY NOT NULL, b INT)
GO

INSERT INTO #t1 (b) values (1)
GO

SELECT * FROM #t1
GO

ALTER TABLE #t1 DROP COLUMN b
GO

SELECT * FROM #t1
GO

ALTER TABLE #t1 ADD b varchar(20)
GO

SELECT * FROM #t1
GO

ALTER TABLE #t1 ADD c AS a + 1
GO

SELECT * FROM #t1
GO

ALTER TABLE #t1 DROP COLUMN a
GO

SELECT * FROM #t1
GO

-- BABEL-5273 ALTER COLUMN to another char type
INSERT INTO #t1 (b) VALUES ('hello')
GO

ALTER TABLE #t1 ALTER COLUMN b char(5)
GO

SELECT * FROM #t1
GO

-- should fail due to possible truncation
ALTER TABLE #t1 ALTER COLUMN b char(4)
GO

ALTER TABLE #t1 DROP COLUMN b
GO

SELECT * FROM #t1
GO

ALTER TABLE #t1 DROP COLUMN c
GO

SELECT * FROM #t1
GO

DROP TABLE #t1
GO
