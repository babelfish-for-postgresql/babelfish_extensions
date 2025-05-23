create table test_tab (a int)
GO

------------------------------------------------------------------------
-- statement terminating error through parallel worker testing starts --
------------------------------------------------------------------------
GO

create table setup_tab1(a bigint)
GO

insert into setup_tab1 values(99999999999999999)
GO

-- simple function whose return expression will throw an error
CREATE FUNCTION stmt_terminating_err()
RETURNS int
AS
BEGIN
    RETURN (SELECT CAST(a AS INT) FROM setup_tab1);  -- This will cause integer out of range error
END
GO

-- simple proc whose return expression will throw an error
CREATE PROCEDURE stmt_terminating_err_proc
AS
BEGIN
    RETURN (SELECT CAST(a AS INT) FROM setup_tab1)
END
GO

-- simple proc whose expression evaluation will throw an error
CREATE PROCEDURE stmt_terminating_err_proc_with_txn
AS
BEGIN
    DECLARE @result int
    BEGIN TRANSACTION
        SELECT @result = CAST(a AS INT) FROM setup_tab1
    COMMIT TRANSACTION
    RETURN (@result)
END
GO

-- Variant 1: Without explicit transaction
CREATE FUNCTION call_error_function_no_txn()
RETURNS int
AS
BEGIN
    RETURN (SELECT dbo.stmt_terminating_err()) -- Direct call without transaction
END
GO

-- Cannot have begin txn inside func
CREATE FUNCTION call_error_function_with_txn()
RETURNS int
AS
BEGIN
    DECLARE @result int
    
    BEGIN TRANSACTION
        SET @result = dbo.stmt_terminating_err()  -- Call within transaction
    COMMIT TRANSACTION
    
    RETURN @result
END
GO

-- variant 2: inner procedure that calls the error function
CREATE PROCEDURE call_error_function_no_txn_proc
AS
BEGIN
    RETURN (SELECT dbo.stmt_terminating_err())
END
GO

-- Variant 3: With explicit transaction
CREATE PROCEDURE call_error_function_with_txn_proc
AS
BEGIN
    BEGIN TRANSACTION;
        DECLARE @result int;
        SET @result = dbo.stmt_terminating_err();
    COMMIT TRANSACTION;
    RETURN @result;
END
GO

-- simple function call without explicit txn
insert into test_tab values (1)
select stmt_terminating_err()
insert into test_tab values (1)
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- simple function call within explicit txn
begin tran
GO
insert into test_tab values (1)
select stmt_terminating_err()
insert into test_tab values (1)
GO

select @@trancount
GO

select * from test_tab;
GO

rollback tran
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- nested function call without explicit txn
insert into test_tab values (1)
select call_error_function_no_txn()
insert into test_tab values (1)
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- nested function call within explicit txn
begin tran
GO
insert into test_tab values (1)
select call_error_function_no_txn()
insert into test_tab values (1)
GO

select @@trancount
GO

select * from test_tab;
GO

rollback tran
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- nested function call through proc without explicit txn
insert into test_tab values (1)
exec call_error_function_no_txn_proc
insert into test_tab values (1)
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- nested function call through proc within explicit txn at batch level
begin tran
GO
insert into test_tab values (1)
exec call_error_function_no_txn_proc
insert into test_tab values (1)
GO

select @@trancount
GO

select * from test_tab;
GO

rollback tran
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- nested function through proc (that starts explicit txn during execution) call without batch level explicit txn
insert into test_tab values (1)
exec call_error_function_with_txn_proc
insert into test_tab values (1)
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- nested function through proc (that starts explicit txn during execution) call within batch levle explicit txn
begin tran
GO
insert into test_tab values (1)
exec call_error_function_with_txn_proc
insert into test_tab values (1)
GO

select @@trancount
GO

select * from test_tab;
GO

rollback tran
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- exec proc without explicit txn
insert into test_tab values (1)
exec stmt_terminating_err_proc;
insert into test_tab values (1)
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- exec proc within explicit txn
begin tran
GO
insert into test_tab values (1)
exec stmt_terminating_err_proc
insert into test_tab values (1)
GO

select @@trancount
GO

select * from test_tab;
GO

rollback tran
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- exec proc (with explicit txn within body) without batch level explicit txn
insert into test_tab values (1)
exec stmt_terminating_err_proc_with_txn;
insert into test_tab values (1)
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- exec proc (with explicit txn within body) with batch level explicit txn
begin tran
GO
insert into test_tab values (1)
exec stmt_terminating_err_proc_with_txn
insert into test_tab values (1)
GO

select @@trancount
GO

select * from test_tab;
GO

rollback tran
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- cleanup
DROP PROCEDURE call_error_function_with_txn_proc
GO

DROP PROCEDURE call_error_function_no_txn_proc
GO

DROP FUNCTION call_error_function_no_txn()
GO

DROP PROCEDURE stmt_terminating_err_proc_with_txn
GO

DROP PROCEDURE stmt_terminating_err_proc
GO

DROP FUNCTION stmt_terminating_err()
GO

drop table setup_tab1
GO

----------------------------------------------
-- statement terminating error testing ends --
----------------------------------------------


---------------------------------------------------------------
-- txn aborting error through parallel worker testing starts --
---------------------------------------------------------------
GO


create table setup_tab2(a varchar(10))
GO

insert into setup_tab2 values ('abc')
GO

-- simple function whose return expression will throw an error
CREATE FUNCTION txn_abort_err()
RETURNS int
AS
BEGIN
    RETURN (select cast( a as int) from setup_tab2);  -- This will cause integer out of range error
END
GO

-- simple proc whose return expression will throw an error
CREATE PROCEDURE txn_abort_err_proc
AS
BEGIN
    RETURN ( select cast( a as int) from setup_tab2)
END
GO

-- simple proc whose expression evaluation will throw an error
CREATE PROCEDURE txn_abort_err_proc_with_txn
AS
BEGIN
    DECLARE @result int
    BEGIN TRANSACTION
        select @result = cast( a as int) from setup_tab2
    COMMIT TRANSACTION
    RETURN (@result)
END
GO

-- Variant 1: Without explicit transaction
CREATE FUNCTION call_error_function_no_txn()
RETURNS int
AS
BEGIN
    RETURN (SELECT dbo.txn_abort_err()) -- Direct call without transaction
END
GO

-- Cannot have begin txn inside func
CREATE FUNCTION call_error_function_with_txn()
RETURNS int
AS
BEGIN
    DECLARE @result int
    
    BEGIN TRANSACTION
        SET @result = dbo.txn_abort_err()  -- Call within transaction
    COMMIT TRANSACTION
    
    RETURN @result
END
GO

-- variant 2: inner procedure that calls the error function
CREATE PROCEDURE call_error_function_no_txn_proc
AS
BEGIN
    RETURN (SELECT dbo.txn_abort_err())
END
GO

-- Variant 3: With explicit transaction
CREATE PROCEDURE call_error_function_with_txn_proc
AS
BEGIN
    BEGIN TRANSACTION;
        DECLARE @result int;
        SET @result = dbo.txn_abort_err();
    COMMIT TRANSACTION;
    RETURN @result;
END
GO

-- simple function call without explicit txn
insert into test_tab values (1)
select txn_abort_err()
insert into test_tab values (1)
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- simple function call within explicit txn
begin tran
GO
insert into test_tab values (1)
select txn_abort_err()
insert into test_tab values (1)
GO

select @@trancount
GO

select * from test_tab;
GO

rollback tran
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- nested function call without explicit txn
insert into test_tab values (1)
select call_error_function_no_txn()
insert into test_tab values (1)
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- nested function call within explicit txn
begin tran
GO
insert into test_tab values (1)
select call_error_function_no_txn()
insert into test_tab values (1)
GO

select @@trancount
GO

select * from test_tab;
GO

rollback tran
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- nested function call through proc without explicit txn
insert into test_tab values (1)
exec call_error_function_no_txn_proc
insert into test_tab values (1)
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- nested function call through proc within explicit txn at batch level
begin tran
GO
insert into test_tab values (1)
exec call_error_function_no_txn_proc
insert into test_tab values (1)
GO

select @@trancount
GO

select * from test_tab;
GO

rollback tran
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- nested function through proc (that starts explicit txn during execution) call without batch level explicit txn
insert into test_tab values (1)
exec call_error_function_with_txn_proc
insert into test_tab values (1)
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- nested function through proc (that starts explicit txn during execution) call within batch levle explicit txn
begin tran
GO
insert into test_tab values (1)
exec call_error_function_with_txn_proc
insert into test_tab values (1)
GO

select @@trancount
GO

select * from test_tab;
GO

rollback tran
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- exec proc without explicit txn
insert into test_tab values (1)
exec txn_abort_err_proc;
insert into test_tab values (1)
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- exec proc within explicit txn
begin tran
GO
insert into test_tab values (1)
exec txn_abort_err_proc
insert into test_tab values (1)
GO

select @@trancount
GO

select * from test_tab;
GO

rollback tran
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- exec proc (with explicit txn within body) without batch level explicit txn
insert into test_tab values (1)
exec txn_abort_err_proc_with_txn;
insert into test_tab values (1)
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- exec proc (with explicit txn within body) with batch level explicit txn
begin tran
GO
insert into test_tab values (1)
exec txn_abort_err_proc_with_txn
insert into test_tab values (1)
GO

select @@trancount
GO

select * from test_tab;
GO

rollback tran
GO

select * from test_tab;
GO

truncate table test_tab
GO

-- cleanup
DROP PROCEDURE call_error_function_with_txn_proc
GO

DROP PROCEDURE call_error_function_no_txn_proc
GO

DROP FUNCTION call_error_function_no_txn()
GO

DROP PROCEDURE txn_abort_err_proc_with_txn
GO

DROP PROCEDURE txn_abort_err_proc
GO

DROP FUNCTION txn_abort_err()
GO

drop table setup_tab2
GO

-------------------------------------------------------------
-- txn aborting error through parallel worker testing ends --
-------------------------------------------------------------

drop table test_tab
GO