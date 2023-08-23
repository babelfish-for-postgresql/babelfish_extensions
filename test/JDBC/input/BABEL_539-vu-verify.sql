EXEC babel_539_prepare_proc
GO

DROP TABLE IF EXISTS babel_539NewTable_proc;
GO

DROP TABLE IF EXISTS babel_539NewTable1;
GO

--calling internal function directly
SELECT col1, IDENTITY_INTO_INT(23, 1,1) as id_num INTO babel_539NewTempTable2 FROM babel_539OldTable;
GO

SELECT sys.IDENTITY(23, 1);
GO

SELECT IDENTITY(int, 21);
GO

SELECT sys.identity_into_int(23, 1, 1);
GO

SELECT sys.IDENTITY_INTO_SMALLINT(21, 1, 1);
GO

SELECT sys.IDENTITY_INTO_INT(23, 1, 1);
GO

SELECT sys.IDENTITY_INTO_BIGINT(20, 1, 1);
GO

SELECT col1, IDENTITY(int,1,1) AS id_num INTO #babel_539NewTable1 FROM babel_539OldTable;
GO

SELECT col1, IDENTITY(int, 1) AS id_num INTO #babel_539NewTable1 FROM babel_539OldTable;
GO

SELECT col1, IDENTITY(int) AS id_num INTO #babel_539NewTable1 FROM babel_539OldTable;
GO