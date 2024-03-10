CREATE TABLE babel_4585_t1(a VARCHAR(10));
GO
INSERT INTO babel_4585_t1 values('2000-12-12');
INSERT INTO babel_4585_t1 values('1000-01-01');
GO

CREATE TABLE babel_4585_t2(id INT);
GO

# JIRA
DECLARE date_cursor CURSOR SCROLL SCROLL FOR SELECT DATEDIFF(Year, GetDate(), a) FROM babel_4585_t1
OPEN date_cursor
FETCH NEXT FROM date_cursor
FETCH NEXT FROM date_cursor
FETCH NEXT FROM date_cursor
CLOSE date_cursor
DEALLOCATE date_cursor
GO

# Cursor should default to type NO SCROLL
DECLARE date_cursor CURSOR SCROLL FOR SELECT DATEDIFF(Year, GetDate(), a) FROM babel_4585_t1
OPEN date_cursor
FETCH PRIOR FROM date_cursor
CLOSE date_cursor
DEALLOCATE date_cursor
GO


# declare cur -> open cur -> insert stmt (forces holdpinned portal)
DECLARE date_cursor CURSOR SCROLL FOR SELECT DATEDIFF(Year, GetDate(), a) FROM babel_4585_t1
OPEN date_cursor
INSERT INTO babel_4585_t2 VALUES (1);
#FETCH NEXT FROM date_cursor
#FETCH NEXT FROM date_cursor
#CLOSE date_cursor
#DEALLOCATE date_cursor
GO

SELECT COUNT(*) FROM babel_4585_t2
DELETE FROM babel_4585_t2
GO

# declare cur -> open cur -> insert stmt (forces holdpinned portal) -> fetch error -> close and reopen cur
DECLARE date_cursor CURSOR SCROLL FOR SELECT DATEDIFF(Year, GetDate(), a) FROM babel_4585_t1
OPEN date_cursor
INSERT INTO babel_4585_t2 VALUES (1);
FETCH NEXT FROM date_cursor
FETCH NEXT FROM date_cursor
CLOSE date_cursor
OPEN date_cursor
FETCH NEXT FROM date_cursor
FETCH NEXT FROM date_cursor
CLOSE date_cursor
DEALLOCATE date_cursor
GO

SELECT COUNT(*) FROM babel_4585_t2
DELETE FROM babel_4585_t2
GO

# declare cur -> open cur -> begin tran -> insert stmt (forces holdpinned portal) -> commit -> fetch next
DECLARE date_cursor CURSOR SCROLL FOR SELECT DATEDIFF(Year, GetDate(), a) FROM babel_4585_t1
OPEN date_cursor
SELECT @@trancount AS ['TRAN NEST COUNT']
BEGIN TRAN
INSERT INTO babel_4585_t2 VALUES (1);
SELECT @@trancount AS ['TRAN NEST COUNT']
FETCH NEXT FROM date_cursor
COMMIT
SELECT @@trancount AS ['TRAN NEST COUNT']
FETCH NEXT FROM date_cursor
CLOSE date_cursor
DEALLOCATE date_cursor
GO

SELECT COUNT(*) FROM babel_4585_t2
DELETE FROM babel_4585_t2
GO

# begin tran -> declare cur -> open cur -> insert stmt (forces holdpinned portal) -> fetch -> fetch -> commit
BEGIN TRAN
GO
DECLARE date_cursor CURSOR SCROLL FOR SELECT DATEDIFF(Year, GetDate(), a) FROM babel_4585_t1
OPEN date_cursor
INSERT INTO babel_4585_t2 VALUES (1);
SELECT @@trancount AS ['TRAN NEST COUNT']
FETCH NEXT FROM date_cursor
FETCH NEXT FROM date_cursor
COMMIT
SELECT @@trancount AS ['TRAN NEST COUNT']
FETCH NEXT FROM date_cursor
CLOSE date_cursor
DEALLOCATE date_cursor
GO

SELECT COUNT(*) FROM babel_4585_t2
DELETE FROM babel_4585_t2
GO


# Use table which will be dropped through rollback -> open cursor after table dropped should throw error
BEGIN TRAN
GO
CREATE TABLE babel_4585_t3(a VARCHAR(10));
GO
INSERT INTO babel_4585_t3 values('2000-12-12');
INSERT INTO babel_4585_t3 values('1000-01-01');
GO
DECLARE date_cursor CURSOR SCROLL FOR SELECT DATEDIFF(Year, GetDate(), a) FROM babel_4585_t3
OPEN date_cursor
INSERT INTO babel_4585_t2 VALUES (1);
SELECT @@trancount AS ['TRAN NEST COUNT']
ROLLBACK
FETCH NEXT FROM date_cursor
FETCH NEXT FROM date_cursor
SELECT @@trancount AS ['TRAN NEST COUNT']
FETCH NEXT FROM date_cursor
CLOSE date_cursor
OPEN date_cursor
FETCH NEXT FROM date_cursor
FETCH NEXT FROM date_cursor
CLOSE date_cursor
DEALLOCATE date_cursor
GO

SELECT COUNT(*) FROM babel_4585_t2
DELETE FROM babel_4585_t2
GO


DROP TABLE IF EXISTS babel_4585_t1, babel_4585_t2, babel_4585_t2
GO