EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'strict';
GO

DROP TABLE if EXISTS t1;
CREATE TABLE t1 (c1 int);
INSERT INTO t1 values (1);
INSERT INTO t1 values (2);
INSERT INTO t1 values (NULL);
GO

SELECT * FROM t1;
SELECT @@rowcount;
GO

SET ROWCOUNT 0;
SELECT @@rowcount;
GO

SELECT * FROM t1;
SELECT @@rowcount;
GO

-- test invalid settings
SET ROWCOUNT 1;
SELECT @@rowcount;
GO

set ROWCOUNT 0;
SELECT @@rowcount;
GO

-- clean up
DROP TABLE t1;
GO

-- reset to default
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'ignore';
GO
