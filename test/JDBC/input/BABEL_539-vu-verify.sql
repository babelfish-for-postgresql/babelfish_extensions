EXEC babel_539_prepare_proc
GO

SELECT col1 INTO babel_539NewTable1 FROM babel_539OldTable;
GO

Select col1 FROM babel_539NewTable1; 
GO

DROP TABLE IF EXISTS babel_539NewTable1;
GO

SELECT col1, IDENTITY(int, 1,1) AS id_num INTO babel_539NewTable1 FROM babel_539OldTable;
GO

Select col1, id_num FROM babel_539NewTable1; 
GO

DROP TABLE IF EXISTS babel_539NewTable1;
GO

SELECT col1, IDENTITY(int, 1) AS id_num INTO #babel_539NewTable1 FROM babel_539OldTable;
GO

Select col1, id_num FROM #babel_539NewTable1; 
GO

DROP TABLE IF EXISTS #babel_539NewTable1;
GO

SELECT col1, IDENTITY(int) AS id_num INTO #babel_539NewTable1 FROM babel_539OldTable;
GO

Select col1, id_num FROM #babel_539NewTable1; 
GO

DROP TABLE IF EXISTS #babel_539NewTable1;
GO

SELECT col1, id_num=IDENTITY(int, 1,1) INTO babel_539NewTable1 FROM babel_539OldTable;
GO

Select col1, id_num FROM #babel_539NewTable1; 
GO

DROP TABLE IF EXISTS #babel_539NewTable1;
GO

SELECT col1, [id_num]=IDENTITY(int, 1,1) INTO #babel_539NewTable1 FROM babel_539OldTable;
GO

Select col1, id_num FROM #babel_539NewTable1; 
GO

DROP TABLE IF EXISTS #babel_539NewTable1;
GO

SELECT col1, IDENTITY(int, 1,1) AS [id_num] INTO #babel_539NewTempTable1 FROM babel_539OldTable;
GO

Select col1, id_num FROM #babel_539NewTempTable1; 
GO

DROP TABLE IF EXISTS #babel_539NewTempTable1;
GO

SELECT *, IDENTITY(int) AS [id_num] INTO #babel_539NewTempTable1 FROM babel_539OldTable;
GO

Select col1, name, id_num FROM #babel_539NewTempTable1; 
GO

DROP TABLE IF EXISTS #babel_539NewTempTable1;
GO

SELECT col1, IDENTITY(char, 1,1) AS id_num INTO babel_539NewTable1 FROM babel_539OldTable;
GO

DROP TABLE IF EXISTS babel_539NewTable1;
GO

SELECT col1, IDENTITY() AS id_num INTO babel_539NewTable1 FROM babel_539OldTable;
GO

-- impact to other similar queries and functions
-- normal create table cases
CREATE TABLE babel_539OldTable2 (col1 int NOT NULL, id_num INT IDENTITY(1, 2));
GO

INSERT INTO babel_539OldTable2 VALUES (10), (20), (30), (40);
GO

SELECT col1, id_num INTO babel_539NewTable2 FROM babel_539OldTable2;
GO

DROP TABLE IF EXISTS babel_539OldTable2;
GO

DROP TABLE IF EXISTS babel_539NewTable2;
GO

-- create table as temp table
CREATE TABLE #babel_539NewTempTable2 (col1 int, id_num int IDENTITY(-1, 2));
GO

INSERT INTO #babel_539NewTempTable2(col1) values (10),(20),(30);
GO

Select col1, id_num FROM #babel_539NewTempTable2; 
GO

DROP TABLE IF EXISTS #babel_539NewTempTable2;
GO

select @@identity;
GO

CREATE TABLE #babel_539NewTempTable2 (col1 int);
GO

Select col1 FROM #babel_539NewTempTable2; 
GO

ALTER TABLE #babel_539NewTempTable2 ADD id_num int IDENTITY(-1, 2);
-- try altering table and check other columns, sequence should drop and any constraints also

Select col1, id_num FROM #babel_539NewTempTable2; 
GO

DROP TABLE IF EXISTS #babel_539NewTempTable2;
GO

-- Two identity columns in a query
SELECT col1, IDENTITY(int, 1,1) as id_num, IDENTITY(int, 1,1) as id_num2 INTO #babel_539NewTempTable2 FROM babel_539OldTable;
GO