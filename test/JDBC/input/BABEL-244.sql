DROP TABLE IF EXISTS t1;
CREATE TABLE t1 (a INT);
GO
 
INSERT INTO t1
VALUES (1), (2);
GO

-- Test by default cursor can be used after commit tran
-- i.e. default setting of cursor_close_on_commit is off

BEGIN TRAN;
DECLARE testcursor CURSOR FOR
    SELECT a FROM t1;
OPEN testcursor;
COMMIT TRAN;
FETCH NEXT FROM testcursor;
CLOSE testcursor;
DEALLOCATE testcursor;
GO

-- test cursor can not be used after close
FETCH NEXT FROM testcursor;
GO

-- Test invalid setting.
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'strict';
SET CURSOR_CLOSE_ON_COMMIT ON;
GO

-- Test CURSOR_CLOSE_ON_COMMIT can be set when escape_hatch_session_settings is ignore
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'ignore';
SET CURSOR_CLOSE_ON_COMMIT ON;
GO

SET CURSOR_CLOSE_ON_COMMIT OFF;
GO

-- Clean up
DROP TABLE t1;
GO
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'ignore';
GO
