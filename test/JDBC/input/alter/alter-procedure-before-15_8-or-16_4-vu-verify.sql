-- Test Case: Expect error for procedure with same name
CREATE PROCEDURE alter_proc_p1 @param1 int
AS
    select * from alter_proc_orders
GO

-- Test Case: Expect error for altering proc that does not exist
ALTER PROCEDURE alter_fake_proc @param1 int
AS
    select * from alter_proc_orders
GO

-- Test Case: Expect p1 and p2 to be altered properly with new definition
exec alter_proc_p1
go

exec alter_proc_p2
go

-- Information_schema routine definition should still show "alter"
select ROUTINE_NAME, ROUTINE_BODY, ROUTINE_DEFINITION from information_schema.routines where SPECIFIC_NAME LIKE 'alter_proc_p1';
go

-- Test Case: Modify the procedure body, add a parameter, use "proc"
--            instead of "procedure"
       ALTER /* TEST COMMENT */ 
            PROC alter_proc_p1
    @param INT
AS
    IF (@param = 1)
    BEGIN
        select * from alter_proc_users
    END

    ELSE
    BEGIN
        select * from alter_proc_orders
    END
GO

exec alter_proc_p1 @param = 1
GO

exec alter_proc_p1 @param = 2
GO

-- Test Case: Expect error because no parameter provided
exec alter_proc_p2
go

-- Test Case: Alter the parameter type and procedure body
ALTER PROCEDURE alter_proc_p1
    @param date
AS
    IF (@param = '2020-01-01')
    BEGIN
        select * from alter_proc_users
    END

    ELSE
    BEGIN
        select * from alter_proc_orders
    END
GO

exec alter_proc_p1 @param = '2020-01-01'
GO

exec alter_proc_p1 @param = '2020-01-02'
GO

-- Test Case: Confirm transaction updates procedure correctly
exec alter_proc_p3 @z = 500
go

-- Ensure information schema uses "CREATE" instead of "ALTER" with updated definition
select ROUTINE_NAME, ROUTINE_BODY, ROUTINE_DEFINITION from information_schema.routines where SPECIFIC_NAME LIKE 'alter_proc_p3';
go

-- Expect this to error with no param provided
exec alter_proc_p3
go

-- Expect procedure altered correctly and information_schema contains comments
exec alter_proc_p4
go

select ROUTINE_NAME, ROUTINE_BODY, ROUTINE_DEFINITION from information_schema.routines where SPECIFIC_NAME LIKE 'alter_proc_p4';
go

-- Test Case: confirm procedure altered to add parameter
exec alter_proc_p5 @dateParam = '2000-01-01'
go

select ROUTINE_NAME, ROUTINE_BODY, ROUTINE_DEFINITION from information_schema.routines where SPECIFIC_NAME LIKE 'alter_proc_p5';
go