USE master
go

-- create user defined type
create type dbo.inttype from int;
GO

-- create stored procedure with arg & default referencing UDT
create proc p4 @v dbo.inttype = cast (1 as dbo.inttype) as SELECT @v;
GO

-- execute default value
EXEC p4
GO

-- execute non-default value
EXEC p4 10
GO

-- test select case
select cast (1 as dbo.inttype);
GO

DROP PROCEDURE p4
GO

DROP TYPE dbo.inttype;
GO
