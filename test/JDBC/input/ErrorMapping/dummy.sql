SELECT @@version
GO

SELECT CURRENT_USER;
GO

EXEC sp_enum_oledb_providers;
GO

-- post setup

-- to check if error is being raised during parse analysis phase
create table error_mapping.temp1 (a int)
GO

-- pre setup

create procedure error_mapping.ErrorHandling1 as
begin
insert into error_mapping.temp1 values(1)
EXEC sp_enum_oledb_providers
end
GO

-- post setup

create table error_mapping.temp2 (a int)
GO

-- pre setup

insert into error_mapping.temp2 values(1)
EXEC sp_enum_oledb_providers
GO

-- post setup

-- Here we are assuming that error_mapping.ErrorHandling1 is created with no error

create table error_mapping.temp3 (a int)
GO

-- pre setup 
insert into error_mapping.temp3 values(1)
exec error_mapping.ErrorHandling1;
GO
 
-- post setup

if ((select count(*) from error_mapping.temp1) = 0 and (select count(*) from error_mapping.temp2) = 0 and (select count(*) from error_mapping.temp3) > 0) select cast('parse analysis phase error' as text)
GO

drop procedure error_mapping.ErrorHandling1;
GO

drop table error_mapping.temp1;
drop table error_mapping.temp2;
drop table error_mapping.temp3;
GO

-- compile time error portion

-- pre setup

create procedure error_mapping.ErrorHandling1 as
begin
EXEC sp_enum_oledb_providers
select cast('STATEMENT TERMINATING ERROR' as text);
select @@trancount;
end
GO

select cast('Compile time error' as text);
if @@trancount > 0 rollback transaction;
set xact_abort OFF;
set implicit_transactions OFF;
GO

-- post setup

-- checking if compile time error rollback the transaction

-- pre setup

begin transaction
GO

create procedure error_mapping.ErrorHandling1 as
begin
EXEC sp_enum_oledb_providers
select cast('STATEMENT TERMINATING ERROR' as text);
end
GO

if (@@trancount > 0) select cast('BATCH ONLY TERMINATING' as text) else select cast('BATCH TERMINATING\ txn rolledback' as text);
if @@trancount > 0 rollback transaction;
drop procedure error_mapping.ErrorHandling1;
set xact_abort OFF;
set implicit_transactions OFF;
GO

-- post setup

-- Checking xact_abort_flag for compile time error 

set xact_abort ON;
GO

-- pre setup

begin transaction
GO

create procedure error_mapping.ErrorHandling1 as
begin
EXEC sp_enum_oledb_providers
select cast('STATEMENT TERMINATING ERROR' as text);
end
GO

if (@@trancount > 0) select cast('BATCH ONLY TERMINATING' as text) else select cast('BATCH TERMINATING\ txn rolledback' as text);
if @@trancount > 0 rollback transaction;
drop procedure error_mapping.ErrorHandling1;
set xact_abort OFF;
set implicit_transactions OFF;
GO

-- post setup

-- Next portion is for runtime error

create procedure error_mapping.ErrorHandling1 as
begin
EXEC sp_enum_oledb_providers
select cast('STATEMENT TERMINATING ERROR' as text);
select @@trancount;
end
GO

create procedure error_mapping.ErrorHandling2 as
begin
exec error_mapping.ErrorHandling1;
select cast('CURRENT BATCH TERMINATING ERROR' as text);
end
GO

begin transaction;
GO
exec error_mapping.ErrorHandling2;
GO
if (@@trancount > 0) select cast('BATCH ONLY TERMINATING' as text) else select cast('BATCH TERMINATING\ txn rolledback' as text);
if @@trancount > 0 rollback transaction;
drop procedure error_mapping.ErrorHandling1;
drop procedure error_mapping.ErrorHandling2;
set xact_abort OFF;
set implicit_transactions OFF;
GO

-- checking xact_abort flag for runtime error

set xact_abort ON;
GO

create procedure error_mapping.ErrorHandling1 as
begin
EXEC sp_enum_oledb_providers
select cast('Does not respect the xact_abort flag' as text);
select @@trancount;
end
GO

create procedure error_mapping.ErrorHandling2 as
begin
exec error_mapping.ErrorHandling1;
select cast('Does not respect the xact_abort flag' as text);
end
GO

begin transaction;
GO
exec error_mapping.ErrorHandling2;
GO
if (@@trancount > 0) select cast('does not respect xact_abort flag' as text) else select cast('respects xact_abort flag' as text);
if @@trancount > 0 rollback transaction;
drop procedure error_mapping.ErrorHandling1;
drop procedure error_mapping.ErrorHandling2;
set xact_abort OFF;
set implicit_transactions OFF;
GO

-- try catch

-- pre setup

create table error_mapping.temp1 (a int)
GO

begin try
insert into error_mapping.temp1 values (1);
EXEC sp_enum_oledb_providers
end try
begin catch
    select xact_state();
    select * from error_mapping.temp1;
end catch
if @@trancount > 0 rollback transaction;
drop procedure error_mapping.ErrorHandling1;
drop procedure error_mapping.ErrorHandling2;
set xact_abort OFF;
set implicit_transactions OFF;
GO

drop table error_mapping.temp1
GO
