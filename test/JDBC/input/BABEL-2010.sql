DECLARE @a VARCHAR(50);
SELECT @a = 'SELECT ''hello world''';
EXEC (@a);
go

-- BABEL-1388, BABEL-2010
DECLARE @a VARCHAR(50);
SELECT @a = 'DROP PROCEDURE myproc';
EXEC @a;
go

-- Error, procedure called does not exist
DECLARE @a VARCHAR(50) = 'babel_2010_proc';
EXEC @a;
go

CREATE PROC babel_2010_proc AS
SELECT 'hello';
go

-- Need support for: 
-- EXEC @module_name_var
-- where @module_name_var is a variable
-- whose value is a proc/func name.
-- Should pass after BABEL-341 is fixed.
DECLARE @a VARCHAR(50) = 'babel_2010_proc';
EXEC @a;
go

DROP PROC babel_2010_proc
go
