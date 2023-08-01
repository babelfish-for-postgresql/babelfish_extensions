EXEC babel_539_prepare_proc
GO

SELECT id_num, col1, name  FROM babel_539NewTable_proc ORDER BY id_num;
GO

DROP TABLE IF EXISTS babel_539NewTable_proc;
GO

DROP TABLE IF EXISTS babel_539NewTable1;
GO

SELECT col1, IDENTITY(int, 1,1) AS id_num INTO babel_539NewTable1 FROM babel_539OldTable;
GO

SELECT id_num, col1 FROM babel_539NewTable1 ORDER BY id_num;
GO

DROP TABLE IF EXISTS babel_539NewTable1;
GO

SELECT col1, IDENTITY(int, 1) AS id_num INTO #babel_539NewTable1 FROM babel_539OldTable;
GO

SELECT id_num, col1 FROM babel_539NewTable1 ORDER BY id_num;
GO

DROP TABLE IF EXISTS #babel_539NewTable1;
GO

SELECT col1, IDENTITY(int) AS id_num INTO #babel_539NewTable1 FROM babel_539OldTable;
GO

SELECT col1, id_num FROM #babel_539NewTable1 ORDER BY id_num;
GO

DROP TABLE IF EXISTS #babel_539NewTable1;
GO

SELECT col1, id_num=IDENTITY(int, 1,100) INTO #babel_539NewTable1 FROM babel_539OldTable;
GO

SELECT id_num, col1 FROM #babel_539NewTable1 ORDER BY id_num;
GO

DROP TABLE IF EXISTS #babel_539NewTable1;
GO

SELECT col1, [id_num]=IDENTITY(int, 1,1) INTO #babel_539NewTable1 FROM babel_539OldTable;
GO

SELECT id_num, col1 FROM #babel_539NewTable1 ORDER BY id_num; 
GO

DROP TABLE IF EXISTS #babel_539NewTable1;
GO

SELECT col1, IDENTITY(int, 1,-100) AS [id_num] INTO #babel_539NewTable1 FROM babel_539OldTable;
GO

SELECT id_num, col1 FROM #babel_539NewTable1 ORDER BY id_num; 
GO

DROP TABLE IF EXISTS #babel_539NewTable1;
GO

SELECT *, IDENTITY(int) AS [id_num] INTO #babel_539NewTable1 FROM babel_539OldTable;
GO

SELECT id_num, col1, name FROM #babel_539NewTable1 ORDER BY id_num; 
GO

DROP TABLE IF EXISTS #babel_539NewTable1;
GO

-- Self Join
SELECT IDENTITY(int,1,1) AS id_num, ltable.col1 AS col1, ltable.name AS name INTO #babel_539NewTable1 
FROM babel_539OldTable AS ltable JOIN babel_539OldTable AS rtable ON ltable.col1 <> rtable.col1 ORDER BY ltable.col1;
GO

SELECT id_num, col1, name FROM #babel_539NewTable1 ORDER BY id_num; 
GO

DROP TABLE IF EXISTS #babel_539NewTable1;
GO

SELECT IDENTITY(bigint, 9223372036854775807, -1) id_num, col1, name INTO #babel_539NewTable1 FROM babel_539OldTable;
GO

SELECT id_num, col1, name FROM #babel_539NewTable1 ORDER BY id_num; 
GO

DROP TABLE IF EXISTS #babel_539NewTable1;
GO

SELECT IDENTITY(numeric, -9223372036854775807, +1) id_num, col1, name INTO #babel_539NewTable1 FROM babel_539OldTable;
GO

SELECT id_num, col1, name FROM #babel_539NewTable1 ORDER BY id_num; 
GO

DROP TABLE IF EXISTS #babel_539NewTable1;
GO

SELECT IDENTITY(numeric(19,0), 9223372036854775807, -1) id_num, col1, name INTO #babel_539NewTable1 FROM babel_539OldTable;
GO

SELECT id_num, col1, name FROM #babel_539NewTable1 ORDER BY id_num; 
GO

DROP TABLE IF EXISTS #babel_539NewTable1;
GO

SELECT distinct IDENTITY(numeric(19,0), 1, 1) as id_num, * into #babel_539NewTable1 from babel_539OldTable where 1=1;
GO

SELECT col1, name, id_num FROM #babel_539NewTable1 ORDER BY id_num; 
GO

DROP TABLE IF EXISTS #babel_539NewTable1;
GO

SELECT col1, IDENTITY(char, 1,1) AS id_num INTO babel_539NewTable1 FROM babel_539OldTable;
GO

-- impact to other similar queries and functions
-- normal create table cases
CREATE TABLE babel_539OldTable2 (col1 int NOT NULL, name varchar(20), id_num INT IDENTITY(1, 2));
GO

INSERT INTO babel_539OldTable2 VALUES (10, 'user1') , (20, 'user2'), (30, 'user3');
GO

SELECT id_num, col1, name INTO babel_539NewTable2 FROM babel_539OldTable2 ORDER BY id_num;
GO

SELECT id_num, col1, name FROM babel_539NewTable2 ORDER BY id_num; 
GO

DROP TABLE IF EXISTS babel_539OldTable2;
GO

DROP TABLE IF EXISTS babel_539NewTable2;
GO

-- create table as temp table
CREATE TABLE #babel_539NewTable2 (col1 int, name varchar(20),  id_num int IDENTITY(-1, 2));
GO

INSERT INTO #babel_539NewTable2(col1, name) VALUES (10, 'user1') , (20, 'user2'), (30, 'user3');
GO

SELECT id_num, col1, name FROM #babel_539NewTable2 ORDER BY id_num; 
GO

DROP TABLE IF EXISTS #babel_539NewTable2;
GO

CREATE TABLE #babel_539NewTable2 (col1 int, name varchar(20) );
GO

SELECT col1, name FROM #babel_539NewTable2 ORDER BY col1; 
GO

-- try altering table and check other columns, sequence should drop and any constraints also
ALTER TABLE #babel_539NewTable2 ADD id_num int IDENTITY(1, 1);
GO

INSERT INTO #babel_539NewTable2(col1, name) VALUES (10, 'user1') , (20, 'user2'), (30, 'user3');
GO

SELECT id_num, col1, name FROM #babel_539NewTable2 ORDER BY id_num; 
GO

DROP TABLE IF EXISTS #babel_539NewTable2;
GO

-- Two identity columns in a query
SELECT col1, IDENTITY(int, 1,1) as id_num, IDENTITY(int, 1,1) as id_num2 INTO babel_539NewTable2 FROM babel_539OldTable;
GO

SELECT col1, IDENTITY() AS id_num INTO babel_539NewTable1 FROM babel_539OldTable;
GO

--calling internal function directly
SELECT col1, IDENTITY_INTO(1, 1,1) as id_num INTO babel_539NewTempTable2 FROM babel_539OldTable;
GO

SELECT sys.IDENTITY(23, 1);
GO

SELECT IDENTITY(int, 21);
GO

SELECT sys.IDENTITY_INTO(23, 1, 1);
GO

SELECT sys.IDENTITY_INTO_SMALLINT(23, 1, 1);
GO

SELECT sys.IDENTITY_INTO_BIGINT(23, 1, 1);
GO

SELECT sys.IDENTITY_INTO_INT(23, 1, 1);
GO