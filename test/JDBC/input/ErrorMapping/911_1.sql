# Executing test ErrorHandling1
--Pre
GO


create procedure ErrorHandling1 as
begin
--database doesn't exist
EXEC('use dbxyz')
if @@error > 0 select cast('STATEMENT TERMINATING ERROR' as text);
select @@trancount;
end
GO

if @@error > 0 select cast('Compile time error' as text);
if @@trancount > 0 rollback transaction;
drop procedure ErrorHandling1;
set xact_abort OFF;
set implicit_transactions OFF;
GO
--Post
GO

--Pre
GO
begin transaction
GO
# Executing test ErrorHandling1

create procedure ErrorHandling1 as
begin
--database doesn't exist
EXEC('use dbxyz')
if @@error > 0 select cast('STATEMENT TERMINATING ERROR' as text);
end
GO

declare @err int = @@error; if (@err > 0 and @@trancount > 0) select cast('BATCH ONLY TERMINATING' as text) else if @err > 0 select cast('BATCH TERMINATING\ txn rolledback' as text);
if @@trancount > 0 rollback transaction;
drop procedure ErrorHandling1;
set xact_abort OFF;
set implicit_transactions OFF;
GO

GO

--Post
GO


-- Checking xact_abort_flag for compile time error --
set xact_abort ON;
GO
--Pre
GO
begin transaction
GO
# Executing test ErrorHandling1

create procedure ErrorHandling1 as
begin
--database doesn't exist
EXEC('use dbxyz')
if @@error > 0 select cast('STATEMENT TERMINATING ERROR' as text);
end
GO

declare @err int = @@error; if (@err > 0 and @@trancount > 0) select cast('BATCH ONLY TERMINATING' as text) else if @err > 0 select cast('BATCH TERMINATING\ txn rolledback' as text);
if @@trancount > 0 rollback transaction;
drop procedure ErrorHandling1;
set xact_abort OFF;
set implicit_transactions OFF;
GO

GO

--Post
GO
set xact_abort OFF;
GO

-- Next portion is for runtime error --
# Executing test ErrorHandling10000000
--Pre
GO

create procedure ErrorHandling1 as
begin
--database doesn't exist
EXEC('use dbxyz')
if @@error > 0 select cast('STATEMENT TERMINATING ERROR' as text);
select @@trancount;
end
GO

if @@error > 0 select cast('CURRENT BATCH TERMINATING ERROR' as text);
GO

create procedure ErrorHandling2 as
begin
exec ErrorHandling1;
if @@error > 0 select cast('CURRENT BATCH TERMINATING ERROR' as text);
end
GO

begin transaction;
GO
exec ErrorHandling2;
GO

declare @err int = @@error; if (@err > 0 and @@trancount > 0) select cast('BATCH ONLY TERMINATING' as text) else if @err > 0 select cast('BATCH TERMINATING\ txn rolledback' as text);
if @@trancount > 0 rollback transaction;
drop procedure ErrorHandling1;
drop procedure ErrorHandling2;
set xact_abort OFF;
set implicit_transactions OFF;
GO
--Post
GO


set xact_abort ON;
GO
# Executing test ErrorHandling10000000
--Pre
GO

create procedure ErrorHandling1 as
begin
--database doesn't exist
EXEC('use dbxyz')
if @@error > 0 select cast('STATEMENT TERMINATING ERROR' as text);
select @@trancount;
end
GO

if @@error > 0 select cast('CURRENT BATCH TERMINATING ERROR' as text);
GO

create procedure ErrorHandling2 as
begin
exec ErrorHandling1;
if @@error > 0 select cast('CURRENT BATCH TERMINATING ERROR' as text);
end
GO

begin transaction;
GO
exec ErrorHandling2;
GO

declare @err int = @@error; if (@err > 0 and @@trancount > 0) select cast('BATCH ONLY TERMINATING' as text) else if @err > 0 select cast('BATCH TERMINATING\ txn rolledback' as text);
if @@trancount > 0 rollback transaction;
drop procedure ErrorHandling1;
drop procedure ErrorHandling2;
set xact_abort OFF;
set implicit_transactions OFF;
GO
--Post
GO



set xact_abort OFF;
GO

-- Error classification is done --
# Executing test ErrorHandling10000000
--Pre
GO



begin try
select 1
--database doesn't exist
EXEC ('use dbxyz')
end try
begin catch
        select xact_state();
end catch
if @@trancount > 0 rollback transaction;
drop procedure ErrorHandling1;
drop procedure ErrorHandling2;
set xact_abort OFF;
set implicit_transactions OFF;
GO

--Post
GO
