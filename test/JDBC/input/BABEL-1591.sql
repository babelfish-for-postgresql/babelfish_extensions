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

-- clean up
DROP FUNCTION IF EXISTS foocommittest
GO

DROP FUNCTION IF EXISTS foorollbacktest
GO

DROP FUNCTION IF EXISTS fooexecutetest
GO

DROP FUNCTION IF EXISTS fooexectest
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