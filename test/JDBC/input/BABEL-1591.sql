-- Allow normal function creation

CREATE FUNCTION babel1591foo1() RETURNS INT AS BEGIN RETURN 10 END
GO

SELECT babel1591foo1();
GO

DROP FUNCTION IF EXISTS babel1591foo1;
GO

-- Below Create function statements having specific keywords should fail
CREATE FUNCTION foocommittest(@p int) RETURNS int AS BEGIN COMMIT RETURN 0 END
GO

CREATE FUNCTION foorollbacktest(@p int) RETURNS int AS BEGIN ROLLBACK RETURN 0 END
GO

CREATE FUNCTION fooexecutetest(@p int) RETURNS int AS BEGIN EXECUTE('select 1') RETURN 0 END
GO

CREATE FUNCTION fooexectest(@p int) RETURNS int AS BEGIN EXEC('select 1') RETURN 0 END
GO

CREATE FUNCTION fooexectestV(@p int) RETURNS int AS BEGIN EXEC(@@trancount) RETURN 0 END
GO

CREATE FUNCTION fsavetrantest(@p int) RETURNS int AS BEGIN SAVE TRAN sp1 RETURN 0 END
GO

CREATE FUNCTION fsavetransactiontest(@p int) RETURNS int AS BEGIN SAVE TRANSACTION sp2 RETURN 0 END
GO

CREATE FUNCTION fwaitfordelay(@p int) RETURNS int AS BEGIN WAITFOR DELAY '00:00:20' RETURN 0 END
GO

CREATE FUNCTION fwaitfortime(@p int) RETURNS int AS BEGIN WAITFOR TIME '00:00:20' RETURN 0 END
GO

CREATE FUNCTION fprinttest (@p int) RETURNS int AS BEGIN PRINT 'hello there' RETURN 0 END
GO

CREATE FUNCTION fraiserrortest (@p int) RETURNS int AS BEGIN RAISERROR(5005, 10, 1, N'ErrorMessage') RETURN 0 END
GO

-- clean up
DROP FUNCTION IF EXISTS foocommittest
GO

DROP FUNCTION IF EXISTS foorollbacktest
GO

DROP FUNCTION IF EXISTS fooexecutetest
GO

DROP FUNCTION IF EXISTS fooexectest
GO

DROP FUNCTION IF EXISTS fooexectestV
GO

DROP FUNCTION IF EXISTS fsavetrantest
GO

DROP FUNCTION IF EXISTS fsavetransactiontest
GO

DROP FUNCTION IF EXISTS fwaitfordelay
GO

DROP FUNCTION IF EXISTS fwaitfortime
GO

DROP FUNCTION IF EXISTS fprinttest
GO

DROP FUNCTION IF EXISTS fraiserrortest
GO

--This needs to be uncommented and tested later when support for alter function is added, 
-- and corresponding test cases for transactions should be added

-- ALTER FUNCTION babel1591foo1() RETURNS INT AS BEGIN RETURN 100; END
-- GO
-- select dbo.babel1591foo1();
-- GO


--  NOT TESTED
-- Below Alter function statements having specific keywords should fail
-- ALTER FUNCTION foocommittest(@p int) RETURNS int AS BEGIN COMMIT RETURN 0 END
-- GO
-- ALTER FUNCTION foorollbacktest(@p int) RETURNS int AS BEGIN ROLLBACK RETURN 0 END
-- GO
-- ALTER FUNCTION fooexecutetest(@p int) RETURNS int AS BEGIN EXECUTE('select 1') RETURN 0 END
-- GO
-- ALTER FUNCTION fooexectest(@p int) RETURNS int AS BEGIN EXEC('select 1') RETURN 0 END
-- GO