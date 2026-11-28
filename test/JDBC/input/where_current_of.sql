-- UPDATE/DELETE ... WHERE CURRENT OF cursor
CREATE TABLE where_current_of_t (id INT PRIMARY KEY, g INT, v INT, acc INT NULL);
INSERT INTO where_current_of_t VALUES (1, 1, 10, NULL), (2, 1, 20, NULL), (3, 1, 30, NULL), (4, 2, 5, NULL), (5, 2, 6, NULL);
CREATE TABLE where_current_of_o (id INT PRIMARY KEY, w INT);
INSERT INTO where_current_of_o VALUES (1, 100), (2, 200);
GO

-- loop in a batch, every statement in its own transaction
DECLARE @v INT;
DECLARE c CURSOR FOR SELECT v FROM where_current_of_t WHERE g = 1 ORDER BY id FOR UPDATE OF acc;
OPEN c;
FETCH c INTO @v;
WHILE @@FETCH_STATUS = 0
BEGIN
	UPDATE where_current_of_t SET acc = @v * 2 WHERE CURRENT OF c;
	FETCH c INTO @v;
END
CLOSE c;
DEALLOCATE c;
GO

SELECT * FROM where_current_of_t ORDER BY id;
GO

-- loop in an explicit transaction, rolled back
BEGIN TRANSACTION;
DECLARE @v INT;
DECLARE c CURSOR FOR SELECT v FROM where_current_of_t ORDER BY id;
OPEN c;
FETCH c INTO @v;
WHILE @@FETCH_STATUS = 0
BEGIN
	UPDATE where_current_of_t SET acc = -1 WHERE CURRENT OF c;
	FETCH c INTO @v;
END
CLOSE c;
DEALLOCATE c;
SELECT count(*) FROM where_current_of_t WHERE acc = -1;
ROLLBACK;
GO

SELECT * FROM where_current_of_t ORDER BY id;
GO

-- in a procedure, with a running total kept in a variable; run twice
CREATE PROCEDURE where_current_of_p @start INT AS
BEGIN
	DECLARE @v INT, @run INT = @start;
	DECLARE c CURSOR LOCAL FORWARD_ONLY FOR SELECT v FROM where_current_of_t WHERE g = 1 ORDER BY id;
	OPEN c;
	FETCH c INTO @v;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE where_current_of_t SET acc = @run, @run = @run + v WHERE CURRENT OF c;
		FETCH c INTO @v;
	END
	CLOSE c;
	DEALLOCATE c;
END
GO

EXEC where_current_of_p 0;
GO

SELECT * FROM where_current_of_t ORDER BY id;
GO

EXEC where_current_of_p 1000;
GO

SELECT * FROM where_current_of_t ORDER BY id;
GO

-- FETCH without INTO returns only the columns of the query
DECLARE c CURSOR FOR SELECT id, v FROM where_current_of_t WHERE g = 2 ORDER BY id;
OPEN c;
FETCH c;
UPDATE where_current_of_t SET acc = 51 WHERE CURRENT OF c;
FETCH NEXT FROM c;
UPDATE where_current_of_t SET acc = 52 WHERE CURRENT OF c;
SELECT @@ROWCOUNT;
CLOSE c;
DEALLOCATE c;
GO

SELECT * FROM where_current_of_t WHERE g = 2 ORDER BY id;
GO

-- SELECT *, table alias, SCROLL cursor, FETCH PRIOR, reopening the cursor, UPDATE ... FROM
DECLARE @a INT, @b INT, @c INT, @d INT;
DECLARE c SCROLL CURSOR FOR SELECT * FROM where_current_of_t AS x ORDER BY id;
OPEN c;
FETCH c INTO @a, @b, @c, @d;
FETCH c INTO @a, @b, @c, @d;
FETCH PRIOR FROM c INTO @a, @b, @c, @d;
UPDATE where_current_of_t SET acc = 111 WHERE CURRENT OF c;
CLOSE c;
OPEN c;
FETCH LAST FROM c INTO @a, @b, @c, @d;
UPDATE x SET acc = 555 FROM where_current_of_t x WHERE CURRENT OF c;
CLOSE c;
DEALLOCATE c;
GO

SELECT * FROM where_current_of_t ORDER BY id;
GO

-- the same row can be updated more than once, and deleted
DECLARE @i INT;
DECLARE c CURSOR FOR SELECT id FROM where_current_of_t WHERE id = 3;
OPEN c;
FETCH c INTO @i;
UPDATE where_current_of_t SET acc = 7 WHERE CURRENT OF c;
UPDATE where_current_of_t SET acc = acc + 1 WHERE CURRENT OF c;
SELECT acc FROM where_current_of_t WHERE id = 3;
DELETE FROM where_current_of_t WHERE CURRENT OF c;
SELECT count(*) FROM where_current_of_t WHERE id = 3;
CLOSE c;
DEALLOCATE c;
GO

-- DELETE in a loop
DECLARE @i INT;
DECLARE c CURSOR FOR SELECT id FROM where_current_of_t WHERE g = 2;
OPEN c;
FETCH c INTO @i;
WHILE @@FETCH_STATUS = 0
BEGIN
	DELETE where_current_of_t WHERE CURRENT OF c;
	FETCH c INTO @i;
END
CLOSE c;
DEALLOCATE c;
GO

SELECT * FROM where_current_of_t ORDER BY id;
GO

-- cursor variable
DECLARE @i INT;
DECLARE @cur CURSOR;
SET @cur = CURSOR FOR SELECT id FROM where_current_of_t ORDER BY id;
OPEN @cur;
FETCH @cur INTO @i;
WHILE @@FETCH_STATUS = 0
BEGIN
	UPDATE where_current_of_t SET acc = @i * 3 WHERE CURRENT OF @cur;
	FETCH @cur INTO @i;
END
CLOSE @cur;
DEALLOCATE @cur;
GO

SELECT * FROM where_current_of_t ORDER BY id;
GO

-- temporary table
CREATE TABLE #where_current_of_tmp (k INT, n INT);
INSERT INTO #where_current_of_tmp VALUES (1, 0), (2, 0);
DECLARE @k INT;
DECLARE c CURSOR FOR SELECT k FROM #where_current_of_tmp;
OPEN c;
FETCH c INTO @k;
WHILE @@FETCH_STATUS = 0
BEGIN
	UPDATE #where_current_of_tmp SET n = @k * 10 WHERE CURRENT OF c;
	FETCH c INTO @k;
END
CLOSE c;
DEALLOCATE c;
SELECT * FROM #where_current_of_tmp ORDER BY k;
DROP TABLE #where_current_of_tmp;
GO

-- errors

-- the row is gone after DELETE
DECLARE @i INT;
DECLARE c CURSOR FOR SELECT id FROM where_current_of_t WHERE id = 2;
OPEN c;
FETCH c INTO @i;
DELETE FROM where_current_of_t WHERE CURRENT OF c;
UPDATE where_current_of_t SET acc = 9 WHERE CURRENT OF c;
GO

-- before the first FETCH
DECLARE c CURSOR FOR SELECT id FROM where_current_of_t;
OPEN c;
UPDATE where_current_of_t SET acc = 9 WHERE CURRENT OF c;
GO

-- after the last row
DECLARE @i INT;
DECLARE c CURSOR FOR SELECT id FROM where_current_of_t WHERE id = 1;
OPEN c;
FETCH c INTO @i;
FETCH c INTO @i;
UPDATE where_current_of_t SET acc = 9 WHERE CURRENT OF c;
GO

-- cursor is not open
DECLARE c CURSOR FOR SELECT id FROM where_current_of_t;
UPDATE where_current_of_t SET acc = 9 WHERE CURRENT OF c;
GO

-- cursor does not exist
UPDATE where_current_of_t SET acc = 9 WHERE CURRENT OF where_current_of_nosuch;
GO

DELETE FROM where_current_of_t WHERE CURRENT OF where_current_of_nosuch;
GO

-- read-only cursors
DECLARE @i INT;
DECLARE c CURSOR READ_ONLY FOR SELECT id FROM where_current_of_t;
OPEN c;
FETCH c INTO @i;
UPDATE where_current_of_t SET acc = 9 WHERE CURRENT OF c;
GO

DECLARE @i INT;
DECLARE c CURSOR FOR SELECT id FROM where_current_of_t FOR READ ONLY;
OPEN c;
FETCH c INTO @i;
UPDATE where_current_of_t SET acc = 9 WHERE CURRENT OF c;
GO

DECLARE @i INT;
DECLARE c CURSOR FAST_FORWARD FOR SELECT id FROM where_current_of_t;
OPEN c;
FETCH c INTO @i;
DELETE FROM where_current_of_t WHERE CURRENT OF c;
GO

DECLARE @i INT;
DECLARE c CURSOR STATIC FOR SELECT id FROM where_current_of_t;
OPEN c;
FETCH c INTO @i;
DELETE FROM where_current_of_t WHERE CURRENT OF c;
GO

-- cursors whose rows are not rows of one table
DECLARE @i INT;
DECLARE c CURSOR FOR SELECT t.id FROM where_current_of_t t JOIN where_current_of_o o ON o.id = t.id;
OPEN c;
FETCH c INTO @i;
UPDATE where_current_of_t SET acc = 9 WHERE CURRENT OF c;
GO

DECLARE @i INT;
DECLARE c CURSOR FOR SELECT max(id) FROM where_current_of_t;
OPEN c;
FETCH c INTO @i;
UPDATE where_current_of_t SET acc = 9 WHERE CURRENT OF c;
GO

-- the cursor is on another table
DECLARE @i INT;
DECLARE c CURSOR FOR SELECT id FROM where_current_of_o WHERE id = 1;
OPEN c;
FETCH c INTO @i;
UPDATE where_current_of_t SET acc = 9 WHERE CURRENT OF c;
GO

-- the row was changed after it was fetched
DECLARE @i INT;
DECLARE c CURSOR FOR SELECT id FROM where_current_of_t WHERE id = 1;
OPEN c;
FETCH c INTO @i;
UPDATE where_current_of_t SET v = v + 1 WHERE id = 1;
UPDATE where_current_of_t SET acc = 9 WHERE CURRENT OF c;
GO

-- GLOBAL cursor is not supported

DECLARE c CURSOR FOR SELECT id FROM where_current_of_t;
OPEN c;
FETCH c;
UPDATE where_current_of_t SET acc = 9 WHERE CURRENT OF GLOBAL c;
GO

-- UPDATE that also assigns a variable (running total), in a cursor loop
CREATE TABLE where_current_of_run (d INT PRIMARY KEY, q INT, acc INT NULL);
INSERT INTO where_current_of_run VALUES (1, 5, NULL), (2, -2, NULL), (3, 7, NULL), (4, 1, NULL);
GO
DECLARE @tot INT = 100, @q INT;
DECLARE c CURSOR FOR SELECT q FROM where_current_of_run ORDER BY d FOR UPDATE OF acc;
OPEN c;
FETCH c INTO @q;
WHILE @@FETCH_STATUS = 0
BEGIN
	UPDATE where_current_of_run SET acc = @tot + q, @tot = @tot + q WHERE CURRENT OF c;
	FETCH c INTO @q;
END
CLOSE c;
DEALLOCATE c;
SELECT @tot AS total;
SELECT * FROM where_current_of_run ORDER BY d;
DROP TABLE where_current_of_run;
GO

-- user columns named like the row identity columns are never taken for them
CREATE TABLE where_current_of_trap (id INT PRIMARY KEY, [##current_of_ctid] BIGINT, [##current_of_xmin] BIGINT, [##current_of_tableoid] BIGINT);
INSERT INTO where_current_of_trap VALUES (1, 123456789, 1, 999999), (2, 987654321, 2, 888888);
GO

-- in a join cursor, which is not updatable
DECLARE c CURSOR FOR SELECT o.w, t.[##current_of_ctid], t.[##current_of_xmin], t.[##current_of_tableoid] FROM where_current_of_trap t JOIN where_current_of_o o ON o.id = t.id ORDER BY t.id;
OPEN c;
FETCH c;
UPDATE where_current_of_trap SET id = id WHERE CURRENT OF c;
GO

DECLARE @w INT, @a BIGINT, @b BIGINT, @c BIGINT;
DECLARE c CURSOR FOR SELECT o.w, t.[##current_of_ctid], t.[##current_of_xmin], t.[##current_of_tableoid] FROM where_current_of_trap t JOIN where_current_of_o o ON o.id = t.id ORDER BY t.id;
OPEN c;
FETCH c INTO @w, @a, @b, @c;
SELECT @w, @a, @b, @c;
DELETE FROM where_current_of_trap WHERE CURRENT OF c;
GO

-- in a single-table cursor, which is updatable
DECLARE c CURSOR FOR SELECT id, [##current_of_ctid], [##current_of_xmin], [##current_of_tableoid] FROM where_current_of_trap ORDER BY id;
OPEN c;
FETCH c;
FETCH c;
UPDATE where_current_of_trap SET [##current_of_xmin] = 22 WHERE CURRENT OF c;
CLOSE c;
DEALLOCATE c;
SELECT * FROM where_current_of_trap ORDER BY id;
GO

INSERT INTO where_current_of_t VALUES (10, 9, 1, NULL), (11, 9, 2, NULL), (12, 9, 3, NULL);
GO

-- through sp_executesql
EXEC sp_executesql N'DECLARE @i INT;
DECLARE c CURSOR FOR SELECT id FROM where_current_of_t WHERE g = @g ORDER BY id;
OPEN c;
FETCH c INTO @i;
UPDATE where_current_of_t SET acc = @i * 100 WHERE CURRENT OF c;
CLOSE c;
DEALLOCATE c;', N'@g INT', @g = 9;
SELECT id, acc FROM where_current_of_t WHERE g = 9 ORDER BY id;
GO

-- optimistic concurrency error caught by TRY/CATCH
DECLARE @i INT;
DECLARE c CURSOR FOR SELECT id FROM where_current_of_t WHERE id = 11;
OPEN c;
FETCH c INTO @i;
UPDATE where_current_of_t SET v = v + 1 WHERE id = 11;
BEGIN TRY
	UPDATE where_current_of_t SET acc = 7 WHERE CURRENT OF c;
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS n, ERROR_MESSAGE() AS msg;
END CATCH
CLOSE c;
DEALLOCATE c;
GO

-- OUTPUT clause without a trigger
DECLARE c CURSOR FOR SELECT id FROM where_current_of_t WHERE g = 9 ORDER BY id;
OPEN c;
FETCH c;
FETCH c;
FETCH c;
UPDATE where_current_of_t SET acc = -1 OUTPUT inserted.id, inserted.acc WHERE CURRENT OF c;
DELETE FROM where_current_of_t OUTPUT deleted.id, deleted.acc WHERE CURRENT OF c;
CLOSE c;
DEALLOCATE c;
SELECT id, v, acc FROM where_current_of_t WHERE g = 9 ORDER BY id;
DELETE FROM where_current_of_t WHERE g = 9;
GO

-- AFTER trigger and OUTPUT clause
CREATE TABLE where_current_of_log (id INT, w INT);
GO
CREATE TRIGGER where_current_of_trg ON where_current_of_o AFTER UPDATE, DELETE AS
BEGIN
	INSERT INTO where_current_of_log SELECT id, w FROM inserted;
	INSERT INTO where_current_of_log SELECT -id, w FROM deleted;
END;
GO
DECLARE c CURSOR FOR SELECT id FROM where_current_of_o ORDER BY id;
OPEN c;
FETCH c;
UPDATE where_current_of_o SET w = w + 1 OUTPUT inserted.id, deleted.w AS old_w, inserted.w AS new_w WHERE CURRENT OF c;
FETCH c;
DELETE FROM where_current_of_o OUTPUT deleted.id, deleted.w WHERE CURRENT OF c;
CLOSE c;
DEALLOCATE c;
SELECT * FROM where_current_of_log ORDER BY id;
SELECT * FROM where_current_of_o ORDER BY id;
GO
DROP TRIGGER where_current_of_trg;
DROP TABLE where_current_of_log;
DROP TABLE where_current_of_trap;
GO

SELECT * FROM where_current_of_t ORDER BY id;
GO

DROP PROCEDURE where_current_of_p;
DROP TABLE where_current_of_t;
DROP TABLE where_current_of_o;
GO
