-- Test Case 1: Alter function body
alter function alter_func_f1() returns int begin return 2 end
go

-- Expect to return 2
select alter_func_f1()
go

-- Confirm information schema is correctly updated with "CREATE FUNC [new definition]" 
select ROUTINE_NAME, ROUTINE_BODY, ROUTINE_DEFINITION from information_schema.routines where SPECIFIC_NAME LIKE 'alter_func_f1';
go

-- Test Case 2: Alter function parameters, body, and return type
ALTER function alter_func_f2(@param2 varchar(10)) returns varchar(10) begin return @param2 end
go

select alter_func_f2('testing')
go

-- Confirm information schema is correctly updated with "CREATE FUNC [new definition]" 
select ROUTINE_NAME, ROUTINE_BODY, ROUTINE_DEFINITION from information_schema.routines where SPECIFIC_NAME LIKE 'alter_func_f2';
go

-- Expect error for no parameter provided
select alter_func_f2()
go

-- Test Case 3: Expect error for altering func that does not exist
ALTER function alter_fake_func(@param1 int) returns int
begin
    return 1
end
GO

-- Test Case 4: Alter parameter type and function body
ALTER function alter_func_f2(@param2 int) returns varchar(10) 
begin 
    if (@param2 = 1)
    BEGIN
        return @param2
    END

    ELSE
    BEGIN
        return -1
    END
end
go

select alter_func_f2(1)
go

select alter_func_f2(2)
go

-- Confirm information schema is correctly updated with "CREATE FUNC [new definition]"
select ROUTINE_NAME, ROUTINE_BODY, ROUTINE_DEFINITION from information_schema.routines where SPECIFIC_NAME LIKE 'alter_func_f2';
go

-- Test Case 5: Transaction - begin, alter func, rollback
--                          - expect alter to not go through
BEGIN TRANSACTION
go

ALTER function alter_func_f2(@param2 varchar(10)) returns varchar(10) begin return @param2 end
go

ROLLBACK
go

-- Expect error
select alter_func_f2('test')
go

-- Expect return 1
select alter_func_f2(1)
go

-- Test Case 6: Transaction - begin, alter func, modify row, commit
--                          - expect both changes to take place 
BEGIN TRANSACTION
GO

ALTER function alter_func_f2(@param2 varchar(10)) returns varchar(10) begin return @param2 end
go

INSERT INTO alter_func_users VALUES (3, 'newuser', 'lastname', 'testemail3')
go

COMMIT
GO

select alter_func_f2('test')
go

select * from alter_func_users
go

-- Confirm information schema is correctly updated with "CREATE FUNC [new definition]" 
select ROUTINE_NAME, ROUTINE_BODY, ROUTINE_DEFINITION from information_schema.routines where SPECIFIC_NAME LIKE 'alter_func_f2';
go

-- Test Case 7: Transaction - begin, alter func, modify row, commit
--                          - expect both changes to not go through
BEGIN TRANSACTION
GO

alter function alter_func_f2() returns int begin return 2 end
go

INSERT INTO alter_func_users VALUES (4, 'newest_user', 'lastname3', 'testemail4')
go

ROLLBACK
GO

-- Expect error for no parameter
select alter_func_f2()
go

-- Expect only 3 rows
select * from alter_func_users
go

-- Test Case 8: Expect error from altering function to select from
--              table row that does not exist
alter function alter_func_f2() returns TABLE 
as 
    return (
        select address from alter_func_users
    )
go

-- Test Case 9: Alter multi statement tvf
alter function alter_func_f5()
returns @result TABLE(Id int) as begin
insert into @result values (2)
return
end
go

select Id from alter_func_f5()
go

-- Add column with different type
alter function alter_func_f5()
returns @result TABLE(Id int, Name varchar(max)) as begin
insert into @result values (2, 'Grace Hopper')
return
end
go

select Id, Name from alter_func_f5()
go

-- Remove a column
alter function alter_func_f5()
returns @result TABLE(Name varchar(max)) as begin
insert into @result values ('Grace Hopper')
return
end
go

-- Expect error for Id column not existing
select Id, Name from alter_func_f5()
go

select Name from alter_func_f5()
go

-- Add column and update condition
alter function alter_func_f5()
returns @result TABLE([Id] int, [email] varchar(50), [Status] varchar(50)) as begin
insert into @result select Id, email, NULL from alter_func_users
update @result set Status =
    case when Id = 1 then 'Owner'
    else 'Normal'
end
return
end
go

select * from alter_func_f5()
go

-- Create same multiline function on schema

create function alter_func_prep_schema1.alter_func_f5() 
returns @result TABLE([Id] int, [email] varchar(50), [Status] varchar(50)) as 
begin 
insert into @result select Id, email, NULL from alter_func_users update @result set Status = case when Id = 1 then 'Owner' else 'Normal' end 
return 
end
go

select * from alter_func_prep_schema1.alter_func_f5()
go

-- Alter function on schema
alter function alter_func_prep_schema1.alter_func_f5() 
returns @result TABLE(Name varchar(max)) as begin insert into @result values ('Grace Hopper') 
return 
end
go

select * from alter_func_prep_schema1.alter_func_f5()
go

-- Alter function on schema with parameters
alter function alter_func_prep_schema1.alter_func_f5(@name varchar(max)) 
returns @result TABLE(Name varchar(max)) as begin insert into @result values (@name) 
return 
end
go

select * from alter_func_prep_schema1.alter_func_f5('Ada Lovelace')
go

-- Test Case 10: Expect error for altering function in an illegal way
--               select statements are not allowed in functions not returning a table
alter function alter_func_f3(@param1 int) returns int 
begin 
    select * from alter_func_users
    return @param1
end
go

-- Test Case 11: Alter function with default values
select alter_func_f6(1, default, 100)
go

alter function alter_func_f6 (@p1 int = 345, @p2 int=123, @p3 int) returns int as begin return @p1 + @p2 + @p3 end
go

select alter_func_f6(default, default, 100)
go