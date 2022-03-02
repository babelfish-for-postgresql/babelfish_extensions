-- simple batch start

GO
CREATE FUNCTION f2733()
returns text
as 
begin 
return 'Hello World'
END

GO
IF object_id(N'f2733', N'FN') IS NOT NULL
    DROP FUNCTION f2733
GO

begin transaction
GO
GO
CREATE FUNCTION f2733()
returns text
as 
begin 
return 'Hello World'
END

GO

-- Below output is only applicable if query is special case. for example, CREATE/ALTER TRIGGER, CREATE/ALTER FUNCTION, CREATE/ALTER PROC, CREATE/ALTER VIEW etc

if (@@trancount > 0) select cast('Txn did not rolled back' as text) else select cast('txn rolled back' as text)
GO

if (@@trancount > 0) rollback tran
GO

IF object_id(N'f2733', N'FN') IS NOT NULL
    DROP FUNCTION f2733
GO

-- simple batch end
GO

set xact_abort on
GO

begin transaction
GO
GO
CREATE FUNCTION f2733()
returns text
as 
begin 
return 'Hello World'
END

GO

-- Below output is only applicable if query is special case. for example, CREATE/ALTER TRIGGER, CREATE/ALTER FUNCTION, CREATE/ALTER PROC, CREATE/ALTER VIEW etc

if (@@trancount > 0) select cast('ignored xact_abort flag' as text) else select cast('does not ignore xact_abort flag' as text)
GO

if (@@trancount > 0) rollback tran
GO

IF object_id(N'f2733', N'FN') IS NOT NULL
    DROP FUNCTION f2733
GO

set xact_abort off
GO