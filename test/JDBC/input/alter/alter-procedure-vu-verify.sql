exec alter_proc_p1
go

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

-- Test Case: Modify the procedure body, and check information_schema updated with spaces
/* Leading comment not included: BABEL-5140 */ ALTER       -- test comment
    PROCEDURE alter_proc_p1
AS
    select * from alter_proc_orders
GO

exec alter_proc_p1
go

exec alter_proc_p2
go

-- Ensure information schema uses "CREATE" instead of "ALTER" with updated definition
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

-- Ensure information schema uses "CREATE" instead of "ALTER" with updated definition
select ROUTINE_NAME, ROUTINE_BODY, ROUTINE_DEFINITION from information_schema.routines where SPECIFIC_NAME LIKE 'alter_proc_p1';
go

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

-- Ensure information schema uses "CREATE" instead of "ALTER" with updated definition
select ROUTINE_NAME, ROUTINE_BODY, ROUTINE_DEFINITION from information_schema.routines where SPECIFIC_NAME LIKE 'alter_proc_p1';
go

-- Test Case: Modify the procedure body to call another modified proc
alter procedure alter_proc_p2
AS
    exec alter_proc_p1 @param = '2020-01-01'
GO

exec alter_proc_p2
go

-- Ensure information schema uses "CREATE" instead of "ALTER" with updated definition
select ROUTINE_NAME, ROUTINE_BODY, ROUTINE_DEFINITION from information_schema.routines where SPECIFIC_NAME LIKE 'alter_proc_p2';
go

-- Test Case: attempt to alter function, expect error for being unsupported

alter function alter_proc_f1()
returns int
as
BEGIN
    return 5
END
go

-- Test Case: Transaction - begin, alter, rollback
--                        - expect alter to not go through
BEGIN TRANSACTION
go

alter procedure alter_proc_p3 as select 2
go

ROLLBACK
go

exec alter_proc_p3
go

-- Test Case: Transaction - begin, alter proc, modify row, commit
--                        - expect both changes to take place                          
BEGIN TRANSACTION
go

alter procedure alter_proc_p3 @z int as select 500 + @z
go

INSERT INTO alter_proc_users VALUES (3, 'newuser', 'lastname', 'testemail3')
go

COMMIT
GO

exec alter_proc_p3 @z = 500
go

select * from alter_proc_users
go

-- Ensure information schema uses "CREATE" instead of "ALTER" with updated definition
select ROUTINE_NAME, ROUTINE_BODY, ROUTINE_DEFINITION from information_schema.routines where SPECIFIC_NAME LIKE 'alter_proc_p3';
go

-- Test Case: Transaction - begin, alter proc, modify row, commit
--                        - expect both changes to not go through 

BEGIN TRANSACTION
go

alter procedure alter_proc_p3 as select 1000
go

INSERT INTO alter_proc_users VALUES (4, 'newest_user', 'lastname3', 'testemail4')
go

ROLLBACK
GO

-- Expect this to error with no param provided
exec alter_proc_p3
go

select * from alter_proc_users
go

-- Test Case: Transaction - alter procedure to select from table row that does not exist
--                          which would result in error if committed

BEGIN TRANSACTION
go

alter procedure alter_proc_p3 as 
    select fake_column from alter_proc_users
go

ROLLBACK
GO

-- Expect this to error with no param provided
exec alter_proc_p3
go


-- Test Case: confirm information_schema.routines is updated properly with comments
alter 

/*
 * test comment 1
 */

-- test comment 2

procedure alter_proc_p4 as select 3
go

exec alter_proc_p4
go

select ROUTINE_NAME, ROUTINE_BODY, ROUTINE_DEFINITION from information_schema.routines where SPECIFIC_NAME LIKE 'alter_proc_p4';
go

-- Test Case: confirm information_schema.routines is updated properly with comments
alter 

-- test comment 1

procedure alter_proc_p4 as select 4
go

exec alter_proc_p4
go

select ROUTINE_NAME, ROUTINE_BODY, ROUTINE_DEFINITION from information_schema.routines where SPECIFIC_NAME LIKE 'alter_proc_p4';
go

-- Test Case: confirm procedure altered in 'alter-procedure-vu-prepare' is properly updated
exec alter_proc_p5 @dateParam = '2000-01-01'
go

select ROUTINE_NAME, ROUTINE_BODY, ROUTINE_DEFINITION from information_schema.routines where SPECIFIC_NAME LIKE 'alter_proc_p5';
go
