-- Generic Set-up
CREATE TABLE testtable (firstcol int, secondcol varchar(128), thirdcol varchar(max));
CREATE TABLE simpletable (a int);
GO

-- Testing simple error scenarios
EXEC sp_describe_undeclared_parameters @tsql = N'INSERT INTO testtable VALUES (@P1, @P2, @P3, @P4)';
GO

EXEC sp_describe_undeclared_parameters @tsql = N'INSERT INTO testtable VALUES (@P1)';
GO

EXEC sp_describe_undeclared_parameters @tsql = N'INSERT INTO simpletable VALUES (1)';
GO

EXEC sp_describe_undeclared_parameters @tsql = N'INSERT INTO simpletable VALUES (@P1), (@P2)'
GO

EXEC sp_describe_undeclared_parameters @tsql = N'INSERT INTO simpletable VALUES (@P1), (@P2), (@P3)'
GO

exec sys.sp_describe_undeclared_parameters N'insert into pg_shadow (a,b,c,d,e,f) values (@a,@b,@c,@d,@e,@f)'
go

-- Done testing simple error scenario

-- Set-up
CREATE SCHEMA error_mapping;
GO
create table error_mapping.temp1 (a int);
GO

create procedure error_mapping.ErrorHandling1 as
begin
insert into error_mapping.temp1 values(1);
EXEC sp_describe_undeclared_parameters @tsql = N'INSERT INTO testtable VALUES (@P1, @P2, @P3, @P4)';
end
GO

create table error_mapping.temp2 (a int);
GO

-- Set-up
insert into error_mapping.temp2 values(1);
EXEC sp_describe_undeclared_parameters @tsql = N'INSERT INTO testtable VALUES (@P1, @P2, @P3, @P4)';
GO

-- Note: assumes error_mapping.ErrorHandling1 created successfully.
create table error_mapping.temp3 (a int);
GO

-- Set-up
insert into error_mapping.temp3 values(1);
exec error_mapping.ErrorHandling1;
GO

if ((select count(*) from error_mapping.temp1) = 0 and (select count(*) from error_mapping.temp2) = 0 and (select count(*) from error_mapping.temp3) > 0) select cast('parse analysis phase error' as text)
GO

drop procedure error_mapping.ErrorHandling1;
GO

drop table error_mapping.temp1;
drop table error_mapping.temp2;
drop table error_mapping.temp3;
GO

-- Start checking compile-time error
create procedure error_mapping.ErrorHandling1 as
begin
EXEC sp_describe_undeclared_parameters @tsql = N'INSERT INTO testtable VALUES (@P1, @P2, @P3, @P4)';
if @@error > 0 select cast('STATEMENT TERMINATING ERROR' as text);
select @@trancount;
end
GO

if @@error > 0 select cast('Compile time error' as text);
if @@trancount > 0 rollback transaction;
drop procedure error_mapping.ErrorHandling1;
set xact_abort OFF;
set implicit_transactions OFF;
GO
-- Done checking compile-time error

-- STart checking if compile time error rollback the transaction
begin transaction
GO

create procedure error_mapping.ErrorHandling1 as
begin
EXEC sp_describe_undeclared_parameters @tsql = N'INSERT INTO testtable VALUES (@P1, @P2, @P3, @P4)';
if @@error > 0 select cast('STATEMENT TERMINATING ERROR' as text);
end
GO

declare @err int = @@error; if (@err > 0 and @@trancount > 0) select cast('BATCH ONLY TERMINATING' as text) else if @err > 0 select cast('BATCH TERMINATING\ txn rolledback' as text);
if @@trancount > 0 rollback transaction;
drop procedure if exists error_mapping.ErrorHandling1;
set xact_abort OFF;
set implicit_transactions OFF;
GO
-- Done checking rollback

-- Checking xact_abort_flag for compile time error
set xact_abort ON;
GO

begin transaction
GO

create procedure error_mapping.ErrorHandling1 as
begin
EXEC sp_describe_undeclared_parameters @tsql = N'INSERT INTO testtable VALUES (@P1, @P2, @P3, @P4)';
if @@error > 0 select cast('STATEMENT TERMINATING ERROR' as text);
end
GO

declare @err int = @@error; if (@err > 0 and @@trancount > 0) select cast('BATCH ONLY TERMINATING' as text) else if @err > 0 select cast('BATCH TERMINATING\ txn rolledback' as text);
if @@trancount > 0 rollback transaction;
drop procedure if exists error_mapping.ErrorHandling1;
set xact_abort OFF;
set implicit_transactions OFF;
GO
-- Done checking xact_abort flag for compile time error

-- Starting checking runtime error
create procedure error_mapping.ErrorHandling1 as
begin
EXEC sp_describe_undeclared_parameters @tsql = N'INSERT INTO testtable VALUES (@P1, @P2, @P3, @P4)';
if @@error > 0 select cast('STATEMENT TERMINATING ERROR' as text);
select @@trancount;
end
GO

create procedure error_mapping.ErrorHandling2 as
begin
exec error_mapping.ErrorHandling1;
if @@error > 0 select cast('CURRENT BATCH TERMINATING ERROR' as text);
end
GO

begin transaction;
GO
exec error_mapping.ErrorHandling2;
GO
declare @err int = @@error; if (@err > 0 and @@trancount > 0) select cast('BATCH ONLY TERMINATING' as text) else if @err > 0 select cast('BATCH TERMINATING\ txn rolledback' as text);
if @@trancount > 0 rollback transaction;
drop procedure error_mapping.ErrorHandling1;
drop procedure error_mapping.ErrorHandling2;
set xact_abort OFF;
set implicit_transactions OFF;
GO
-- Done checking runtime error

-- Start checking xact_abort flag for runtime error
set xact_abort ON;
GO

create procedure error_mapping.ErrorHandling1 as
begin
EXEC sp_describe_undeclared_parameters @tsql = N'INSERT INTO testtable VALUES (@P1, @P2, @P3, @P4)';
if @@error > 0 select cast('Does not respect the xact_abort flag' as text);
select @@trancount;
end
GO

create procedure error_mapping.ErrorHandling2 as
begin
exec error_mapping.ErrorHandling1;
if @@error > 0 select cast('Does not respect the xact_abort flag' as text);
end
GO

begin transaction;
GO
exec error_mapping.ErrorHandling2;
GO
declare @err int = @@error; if (@err > 0 and @@trancount > 0) select cast('does not respect xact_abort flag' as text) else if @err > 0 select cast('respects xact_abort flag' as text);
if @@trancount > 0 rollback transaction;
drop procedure error_mapping.ErrorHandling1;
drop procedure error_mapping.ErrorHandling2;
set xact_abort OFF;
set implicit_transactions OFF;
GO
-- Done xact_abort flag


-- Start try catch

-- pre setup
create table error_mapping.temp1 (a int)
GO

begin try
insert into error_mapping.temp1 values (1);
EXEC sp_describe_undeclared_parameters @tsql = N'INSERT INTO testtable VALUES (@P1, @P2, @P3, @P4)';
end try
begin catch
    select xact_state();
    select * from error_mapping.temp1;
end catch
if @@trancount > 0 rollback transaction;
drop procedure error_mapping.ErrorHandling1;
drop procedure error_mapping.ErrorHandling2;
drop table error_mapping.temp1;
set xact_abort OFF;
set implicit_transactions OFF;
GO

drop table error_mapping.temp1
GO
-- Done try/catch

-- cleanup
DROP TABLE IF EXISTS testtable;
DROP TABLE IF EXISTS simpletable;
DROP SCHEMA error_mapping;
GO