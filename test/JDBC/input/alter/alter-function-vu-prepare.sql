CREATE TABLE alter_func_users ([Id] int, [firstname] varchar(50), [lastname] varchar(50), [email] varchar(50));
CREATE TABLE alter_func_orders ([Id] int, [userid] int, [productid] int, [quantity] int, [orderdate] Date);

INSERT INTO alter_func_users VALUES (1, 'j', 'o', 'testemail'), (2, 'e', 'l', 'testemail2');
INSERT INTO alter_func_orders VALUES (1, 1, 1, 5, '2023-06-25'), (2, 1, 1, 6, '2023-06-25');
GO

create function alter_func_f1() returns int begin return 2 end
go

create function alter_func_f2(@param1 int) returns int begin return @param1 end
go

create function alter_func_f3(@param1 int) returns int 
begin 
    if (@param1 < 2)
    begin
        return 1
    end
    else
    begin
        return @param1
    end
end
go

create function alter_func_f4() returns TABLE as return (select * from alter_func_users)
go

-- Test Case: Alter function in prepare file
alter function alter_func_f4() returns TABLE as return (select * from alter_func_orders)
go

select alter_func_f4()
go

create function alter_func_f5() returns @result TABLE([Id] int) as begin insert @result select 1 return end
go

create function alter_func_f6(@p1 int, @p2 int=123, @p3 int) returns int as begin return @p1 + @p2 + @p3 end
go

create schema alter_func_prep_schema1
go