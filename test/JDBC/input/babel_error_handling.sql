CREATE TABLE t1 ( a int primary key );
GO

INSERT INTO t1 VALUES (1);
GO

--
-- Basic error handling behaviors
--

CREATE PROCEDURE proc_insert1 @a int AS
BEGIN
INSERT INTO t1 VALUES (@a);
IF @@error = 2627
    PRINT 'DUPLICATE KEY DETECTED';
IF @@error = 0
    PRINT 'INSERTED @a'

INSERT INTO t1 VALUES (@a+1);

IF @@error = 2627
    PRINT 'DUPLICATE KEY DETECTED @a+1';
IF @@error = 0
    PRINT 'INSERTED @a+1';
END
GO

--
-- entire transaction will be aborted
-- no rows will be inserted
--

EXEC proc_insert1 1
GO

SELECT * FROM t1 ORDER BY a;
GO

-- sub-transaction is aborted and outer transaction continues
EXEC proc_insert1 1
GO

SELECT * FROM t1 ORDER BY a;
GO

-- clean up
DROP TABLE t1;
GO
DROP PROCEDURE proc_insert1;
GO
