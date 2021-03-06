-- Test outside of a procedure
SELECT @@PROCID;
GO

-- Test procedure
CREATE PROCEDURE demo_proc1
AS
DECLARE @proc_name sysname;
DECLARE @msg varchar(100);
SET @proc_name = OBJECT_NAME(@@PROCID);
SET @msg = 'Running stored procedure ' + @proc_name + '!';
SELECT @msg;
GO

EXEC demo_proc1;
GO

-- Test nested procedure
CREATE PROCEDURE demo_proc2
AS
DECLARE @proc_name sysname;
DECLARE @msg varchar(100);
EXEC demo_proc1;
SET @proc_name = OBJECT_NAME(@@PROCID);
SET @msg = 'Running stored procedure ' + @proc_name + '!';
SELECT @msg;
EXEC demo_proc1;
GO

EXEC demo_proc2;
GO

DROP PROCEDURE demo_proc2;
GO

-- Test UDF function
CREATE FUNCTION demo_func1()
RETURNS varchar(100)
AS
BEGIN
	DECLARE @name varchar(100);
	SET @name = 'Running function ' + OBJECT_NAME(@@PROCID) + '!';
	RETURN @name;
END;
GO

SELECT demo_func1();
GO

-- Test nested function inside a procedure
CREATE PROCEDURE demo_proc2
AS
DECLARE @proc_name sysname;
DECLARE @msg varchar(100);
-- Execute another procedure
EXEC demo_proc1;
-- Call a function
SELECT demo_func1();
-- Execute this procedure
SET @proc_name = OBJECT_NAME(@@PROCID);
SET @msg = 'Running stored procedure ' + @proc_name + '!';
SELECT @msg;
-- Again execute another procedure
EXEC demo_proc1;
GO

EXEC demo_proc2;
GO

DROP PROCEDURE demo_proc2;
GO

-- Test nested function inside a function
CREATE FUNCTION demo_func2()
RETURNS varchar(100)
AS
BEGIN
	DECLARE @name varchar(100);
	SET @name = OBJECT_NAME(@@PROCID);
	RETURN @name;
END
GO

CREATE FUNCTION demo_func3()
RETURNS TABLE AS
RETURN
(
	SELECT demo_func2() as nested_function, OBJECT_NAME(@@PROCID) as current_function
)
GO

SELECT * FROM demo_func3();
GO

DROP FUNCTION demo_func2;
DROP FUNCTION demo_func3;
GO

-- Test triggers
CREATE TABLE data (a int NOT NULL);
GO

CREATE TABLE data_log (procedure_name sysname NULL);
GO

CREATE TRIGGER trg_data_log ON data AFTER INSERT
AS
INSERT INTO data_log(procedure_name) VALUES(OBJECT_NAME(@@PROCID));
GO

INSERT INTO data(a) VALUES(1);
GO

-- Should print name of the trigger
SELECT * FROM data_log;
GO

DROP TRIGGER trg_data_log;
DROP TABLE data_log;
GO

--Test nested function and procedure inside a trigger
CREATE TRIGGER trg_call_modules ON data AFTER INSERT
AS
-- Execute procedure
EXEC demo_proc1;
-- Call function
SELECT demo_func1();
-- Print name of this trigger
DECLARE @msg varchar(100);
SET @msg = 'Inside trigger ' + OBJECT_NAME(@@PROCID) + '!';
SELECT @msg;
GO

INSERT INTO data(a) VALUES(1);
GO

DROP PROCEDURE demo_proc1;
DROP FUNCTION demo_func1;
DROP TRIGGER trg_call_modules;
GO

-- Test when nested module throws error
CREATE PROCEDURE demo_proc1
AS
RAISERROR('Procedure demo_proc1 failed', 16, 1);
GO

CREATE PROCEDURE demo_proc2
AS
BEGIN TRY
	EXEC demo_proc1;
END TRY
BEGIN CATCH
	DECLARE @msg varchar(100);
	SET @msg = 'Running procedure ' + OBJECT_NAME(@@PROCID);
	SELECT @msg;
END CATCH;
GO

EXEC demo_proc2;
GO

CREATE TRIGGER trg_err_check ON data AFTER INSERT
AS
BEGIN TRY
	EXEC demo_proc1;
END TRY
BEGIN CATCH
	DECLARE @msg varchar(100);
	SET @msg = 'Running trigger ' + OBJECT_NAME(@@PROCID);
	SELECT @msg;
END CATCH;
GO

INSERT INTO data(a) VALUES(3);
GO

-- Test insert through a procedure
CREATE PROCEDURE table_insert
@val INT
AS
-- Insert will invoke the trigger
INSERT INTO data(a) VALUES(@val);
DECLARE @msg varchar(100);
SET @msg = 'Running procedure ' + OBJECT_NAME(@@PROCID);
SELECT @msg;
GO

EXEC table_insert 4;
GO

DROP TRIGGER trg_err_check;
DROP TABLE data;
DROP PROCEDURE table_insert;
DROP PROCEDURE demo_proc2;
DROP PROCEDURE demo_proc1;
GO
