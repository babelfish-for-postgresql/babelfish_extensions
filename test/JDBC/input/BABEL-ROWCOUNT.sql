USE master;
GO

CREATE TABLE babel_rowcount(test_id INT IDENTITY, test_col1 INT);
GO

CREATE PROCEDURE babel_rowcount_insert
AS BEGIN
    INSERT INTO babel_rowcount (test_col1) VALUES (10), (10), (10)

    IF @@ROWCOUNT <> 3 PRINT @@ROWCOUNT

    INSERT INTO babel_rowcount (test_col1) VALUES (20)
    INSERT INTO babel_rowcount (test_col1) VALUES (20)

    IF @@ROWCOUNT <> 1 PRINT @@ROWCOUNT
END;
GO

CREATE PROCEDURE babel_rowcount_select
AS BEGIN
    SELECT * FROM babel_rowcount
    IF @@ROWCOUNT <> 5 PRINT @@ROWCOUNT
END;
GO

CREATE PROCEDURE babel_rowcount_update
AS BEGIN
    UPDATE babel_rowcount SET test_col1 = 1 WHERE test_col1 = 10

    IF @@ROWCOUNT <> 3 PRINT @@ROWCOUNT

    UPDATE babel_rowcount SET test_col1 = 2 WHERE test_col1 = 20

    IF @@ROWCOUNT <> 2 PRINT @@ROWCOUNT
END;
GO

CREATE PROCEDURE babel_rowcount_select_set
AS BEGIN
    DECLARE @v int
    SELECT @v = test_col1 FROM babel_rowcount
    IF @@ROWCOUNT <> 5 PRINT @@ROWCOUNT
END;
GO

CREATE PROCEDURE babel_rowcount_delete
AS BEGIN
    DELETE FROM babel_rowcount WHERE test_col1 = 1

    IF @@ROWCOUNT <> 3 PRINT @@ROWCOUNT

    DELETE FROM babel_rowcount WHERE test_col1 = 2

    IF @@ROWCOUNT <> 2 PRINT @@ROWCOUNT
END;
GO

CREATE PROCEDURE babel_rowcount_basic_statements
AS BEGIN
    DECLARE @v int
    SET @v = 42
    IF @@ROWCOUNT <> 1 raiserror('ROWCOUNT should be 1', 11, 1)
    print @v
    IF @@ROWCOUNT <> 0 raiserror('ROWCOUNT should be 0', 11, 1)
END;
GO

CREATE PROCEDURE babel_rowcount_return
AS BEGIN
    RETURN 1
END;
GO

EXEC babel_rowcount_insert;
GO
EXEC babel_rowcount_select;
GO
EXEC babel_rowcount_update;
GO
-- Expect 2. Implicit return does not affect value
SELECT @@ROWCOUNT;
GO
EXEC babel_rowcount_select_set;
GO
EXEC babel_rowcount_return;
GO
-- Expect 1. Explicit return resets to 1
SELECT @@ROWCOUNT;
GO
EXEC babel_rowcount_delete;
GO
EXEC babel_rowcount_basic_statements;
GO

-- Clean up
DROP TABLE babel_rowcount;
GO
DROP PROCEDURE babel_rowcount_insert;
GO
DROP PROCEDURE babel_rowcount_select;
GO
DROP PROCEDURE babel_rowcount_update;
GO
DROP PROCEDURE babel_rowcount_select_set;
GO
DROP PROCEDURE babel_rowcount_return;
GO
DROP PROCEDURE babel_rowcount_delete;
GO
DROP PROCEDURE babel_rowcount_basic_statements;
GO