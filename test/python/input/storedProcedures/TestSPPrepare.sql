--- Simple SP_PREPARE
DECLARE @handle int;
EXEC SP_PREPARE @handle, NULL, 'SELECT ''OK'''
EXEC SP_EXECUTE @handle
EXEC SP_EXECUTE @handle
EXEC SP_EXECUTE @handle
EXEC SP_UNPREPARE @handle
GO

--- Simple SP_PREPEXEC
DECLARE @handle int;
EXEC SP_PREPEXEC @handle OUT, NULL, 'SELECT ''OK'''
EXEC SP_EXECUTE @handle
EXEC SP_EXECUTE @handle
EXEC SP_EXECUTE @handle
EXEC SP_UNPREPARE @handle
GO

--- Basic SP_PREPARE with args
DECLARE @handle int;
EXEC SP_PREPARE @handle out, N'@a int, @b int', N'select @a, @b', 10;
EXEC SP_EXECUTE @handle, 1, 2
EXEC SP_EXECUTE @handle, 1, 2
EXEC SP_EXECUTE @handle, 1, 2
EXEC SP_UNPREPARE @handle;
GO

--- Basic SP_PREPARE with args
DECLARE @handle int;
EXEC SP_PREPEXEC @handle out, N'@a int, @b int', N'select @a, @b', 1, 2;
EXEC SP_EXECUTE @handle, 1, 2
EXEC SP_EXECUTE @handle, 1, 2
EXEC SP_EXECUTE @handle, 1, 2
EXEC SP_UNPREPARE @handle;
GO

--- SP_PREPARE Batch Support
DECLARE @handle int;
DECLARE @batch nvarchar(500);
DECLARE @paramdef nvarchar(500);
DECLARE @var int;
SET @batch = 'IF (@cond > 0) SELECT @o = @a ELSE SELECT @o = @b'
SET @paramdef = '@cond int, @a int, @b int, @o int OUTPUT'
EXEC SP_PREPARE @handle, @paramdef, @batch
EXEC SP_EXECUTE @handle, -1, 10, 20, @var OUTPUT
SELECT @var
EXEC SP_EXECUTE @handle, 1, 10, 20, @var OUTPUT
SELECT @var
EXEC SP_UNPREPARE @handle;
GO

--- SP_PREPEXEC Batch Support
DECLARE @handle int;
DECLARE @batch nvarchar(500);
DECLARE @paramdef nvarchar(500);
DECLARE @var int;
SET @batch = 'IF (@cond > 0) SELECT @o = @a ELSE SELECT @o = @b'
SET @paramdef = '@cond int, @a int, @b int, @o int OUTPUT'
EXEC SP_PREPEXEC @handle out, @paramdef, @batch, 1, 30, 40, @var OUTPUT
SELECT @var
EXEC SP_EXECUTE @handle, -1, 10, 20, @var OUTPUT
SELECT @var
EXEC SP_EXECUTE @handle, 1, 10, 20, @var OUTPUT
SELECT @var
EXEC SP_UNPREPARE @handle;
GO

--- Parsing specific 
DECLARE @handle int;
EXEC SP_PREPEXEC @handle + 1 OUTPUT, NULL, 'SELECT 1'
GO

DECLARE @handle VARCHAR(20)
EXEC SP_PREPEXEC @handle OUTPUT, NULL, 'SELECT 1'
GO

DECLARE @handle int;
EXEC SP_PREPEXEC @handle, NULL, 'SELECT 1'
GO

--- Corner case 1: empty batch
DECLARE @handle int;
EXEC SP_PREPARE @handle out, NULL, NULL
EXEC SP_EXECUTE @handle
EXEC SP_UNPREPARE @handle
GO

DECLARE @handle int;
EXEC SP_PREPEXEC @handle out, NULL, NULL
EXEC SP_EXECUTE @handle
EXEC SP_UNPREPARE @handle
GO

--- Corner case 2: nested prepare
DECLARE @handle int;
DECLARE @inner_handle int;
DECLARE @batch VARCHAR(500);
SET @batch = 'EXEC SP_PREPARE @inner_handle OUT, NULL, ''SELECT 1'' '
EXEC SP_PREPARE @handle out, '@inner_handle int OUT', @batch
EXEC SP_EXECUTE @handle, @inner_handle OUT
EXEC SP_EXECUTE @inner_handle
EXEC SP_UNPREPARE @inner_handle  -- unprepare inner first
EXEC SP_UNPREPARE @handle
GO

DECLARE @handle int;
DECLARE @inner_handle int;
DECLARE @batch VARCHAR(500);
SET @batch = 'EXEC SP_PREPARE @inner_handle OUT, NULL, ''SELECT 1'' '
EXEC SP_PREPARE @handle out, '@inner_handle int OUT', @batch
EXEC SP_EXECUTE @handle, @inner_handle OUT
EXEC SP_EXECUTE @inner_handle
EXEC SP_UNPREPARE @handle            --unprepare outer first
EXEC SP_EXECUTE @inner_handle
EXEC SP_UNPREPARE @inner_handle
GO

--- Corner case 3: mismatch paramdef and params
DECLARE @handle int;
DECLARE @var int;
DECLARE @batch VARCHAR(500);
DECLARE @paramdef VARCHAR(500);
SET @batch = 'SELECT @a';
SET @paramdef = '@a int';
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 100
EXEC SP_EXECUTE @handle, @var OUT
EXEC SP_UNPREPARE @handle
GO

--- Prepare DML statement
CREATE TABLE t1 (a int, b int); 
GO

DECLARE @handle int;
DECLARE @batch VARCHAR(500);
DECLARE @paramdef VARCHAR(500);
SET @batch = '
INSERT INTO t1 VALUES (@v1, @v2)
INSERT INTO t1 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 int, @v2 int, @v3 int, @v4 int'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 1, 2, 2, 3
EXEC SP_EXECUTE @handle, 3, 4, 4, 5
SELECT * FROM t1 ORDER BY 1, 2;
GO

DECLARE @handle int;
DECLARE @batch VARCHAR(500);
DECLARE @paramdef VARCHAR(500);
SET @batch = '
UPDATE t1 SET a = a * 10, b = b *10 where a = @var1;
UPDATE t1 SET a = a * 10, b = b *10 where a = @var2;
'
SET @paramdef = '@var1 int, @var2 int'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 1, 2
EXEC SP_EXECUTE @handle, 3, 4
SELECT * FROM t1 ORDER BY 1, 2;

EXEC SP_UNPREPARE @handle
DROP TABLE t1;
GO

--- Transaction with SP_EXECUTE
CREATE TABLE t1 (a int, b int); 
GO

DECLARE @handle int;
DECLARE @batch VARCHAR(500);
DECLARE @paramdef VARCHAR(500);
SET @batch = '
INSERT INTO t1 VALUES (@v1, @v2);
INSERT INTO t1 VALUES (@v3, @v4);
'
SET @paramdef = '@v1 int, @v2 int, @v3 int, @v4 int'

EXEC SP_PREPARE @handle OUT, @paramdef, @batch

BEGIN TRANSACTION;
EXEC SP_EXECUTE @handle, 1, 2, 2, 3
SELECT * FROM t1 ORDER BY 1, 2;
COMMIT;
SELECT * FROM t1 ORDER BY 1, 2;

BEGIN TRANSACTION;
EXEC SP_EXECUTE @handle, 3, 4, 4, 5
SELECT * FROM t1 ORDER BY 1, 2;
ROLLBACK;
SELECT * FROM t1 ORDER BY 1, 2;

EXEC SP_UNPREPARE @handle
GO

DROP TABLE t1;
GO

--- PREPARE Batch with Transaction 
CREATE TABLE t1 (a int, b int); 
GO

DECLARE @handle int;
DECLARE @batch VARCHAR(500);
DECLARE @paramdef VARCHAR(500);
SET @batch = '
BEGIN TRANSACTION
INSERT INTO t1 VALUES (@v1, @v2);
INSERT INTO t1 VALUES (@v3, @v4);
SELECT * FROM t1 ORDER BY 1, 2;
IF (@v1 = 10)
  	COMMIT;
ELSE
	ROLLBACK;
'
SET @paramdef = '@v1 int, @v2 int, @v3 int, @v4 int'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 10, 20, 30, 40
SELECT * FROM t1 ORDER BY 1, 2;
EXEC SP_EXECUTE @handle, 50, 60, 70, 80
SELECT * FROM t1 ORDER BY 1, 2;

EXEC SP_UNPREPARE @handle
GO

DROP TABLE t1;
GO

-- Test Save Point
CREATE TABLE t1 ( a int, b int);
GO

DECLARE @handle int;
DECLARE @batch VARCHAR(500);
SET @batch = '
DECLARE @handle int;
BEGIN TRANSACTION;
INSERT INTO t1 VALUES (1, 2);
SAVE TRANSACTION my_savept;
EXEC SP_PREPEXEC @handle OUT, NULL, 
''INSERT INTO t1 VALUES (3, 4);
  SELECT * FROM t1 ORDER BY 1, 2;
  ROLLBACK TRANSACTION my_savept;
  SELECT * FROM t1 ORDER BY 1, 2;
'';
SELECT * FROM t1 ORDER BY 1, 2;
ROLLBACK;
SELECT * FROM t1 ORDER BY 1, 2;
EXEC SP_UNPREPARE @handle;
'
EXEC SP_PREPARE @handle OUT, NULL, @batch;
PRINT @handle
EXEC SP_EXECUTE @handle;
EXEC SP_UNPREPARE @handle;
GO

DROP TABLE t1;
GO

--- Test string type
CREATE TABLE t1 ( a VARCHAR(10), b VARCHAR(10));
GO

DECLARE @handle int;
EXEC SP_PREPEXEC @handle OUT, '@v1 VARCHAR(10), @v2 VARCHAR(10)', 'INSERT INTO t1 VALUES (@v1,@v2)', 'abc', 'efg'
EXEC SP_EXECUTE @handle, 'lmn', 'opq'
EXEC SP_UNPREPARE @handle
SELECT * FROM t1 ORDER BY 1, 2;
GO

DROP TABLE t1;
GO

-- Test transaction begins outside the batch and commited/rollbacked inside the batch
CREATE TABLE t1 (a INT);
GO

BEGIN TRAN;
GO
DECLARE @handle INT;
DECLARE @batch VARCHAR(500);
SET @batch = 'insert into t1 values(1); commit; begin tran;'
EXEC sp_prepare @handle OUT, NULL, @batch
EXEC sp_execute @handle
EXEC sp_execute @handle
EXEC SP_UNPREPARE @handle;
COMMIT;
SELECT COUNT(*) FROM t1;
GO

BEGIN TRAN;
GO
DECLARE @handle INT;
DECLARE @batch VARCHAR(500);
SET @batch = 'insert into t1 values(1); rollback tran; begin tran;'
EXEC sp_prepare @handle OUT, NULL, @batch
EXEC sp_execute @handle
EXEC sp_execute @handle
EXEC SP_UNPREPARE @handle;
COMMIT;
SELECT COUNT(*) FROM t1;
GO

DROP TABLE t1;
GO

-- prepare time error 1
DECLARE @handle int;
EXEC SP_PREPARE @handle OUT, NULL, 'SELECT * FROM t1'
SELECT @handle IS NOT NULL as 'Prepared'
GO

-- prepare time error 1-2
DECLARE @handle int;
EXEC SP_PREPARE @handle OUT, NULL, 'DECLARE @var int; SELECT * FROM t1 WHERE c = @var'
SELECT @handle IS NOT NULL as 'Prepared'
GO

-- prepare time error 2
DECLARE @handle int;
EXEC SP_PREPARE @handle OUT, NULL, 'EXEC my_proc'
SELECT @handle IS NOT NULL as 'Prepared'
GO

-- prepare time error 2-2
DECLARE @handle int;
EXEC SP_PREPARE @handle OUT, NULL, 'DECLARE @var int; EXEC my_proc @var'
SELECT @handle IS NOT NULL as 'Prepared'
GO

-- runtime error 1
DECLARE @handle int;
EXEC SP_PREPARE @handle OUT, NULL, 'SELECT * FROM t1; SELECT * FROM t1;'
SELECT @handle IS NOT NULL as 'Prepared'
EXEC SP_EXECUTE @handle
GO

-- runtime error 2
DECLARE @handle int;
EXEC SP_PREPARE @handle OUT, NULL, 'EXEC my_proc; EXEC my_proc;'
SELECT @handle IS NOT NULL as 'Prepared'
EXEC SP_EXECUTE @handle
GO

-- runtime error 3
DECLARE @handle int;
EXEC SP_PREPARE @handle OUT, NULL, 'IF (1=1) SELECT * FROM t1;'
SELECT @handle IS NOT NULL as 'Prepared'
EXEC SP_EXECUTE @handle
GO

-- runtime error 4
DECLARE @handle int;
EXEC SP_PREPARE @handle OUT, NULL, 'DECLARE @var int; SET @var = 1; select * from t1 where c = @var'
SELECT @handle IS NOT NULL as 'Prepared'
EXEC SP_EXECUTE @handle
GO
