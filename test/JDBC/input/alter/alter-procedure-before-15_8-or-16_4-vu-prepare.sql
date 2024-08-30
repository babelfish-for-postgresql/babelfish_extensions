CREATE TABLE alter_proc_users ([Id] int, [firstname] varchar(50), [lastname] varchar(50), [email] varchar(50));
CREATE TABLE alter_proc_orders ([Id] int, [userid] int, [productid] int, [quantity] int, [orderdate] Date);

INSERT INTO alter_proc_users VALUES (1, 'j', 'o', 'testemail'), (1, 'e', 'l', 'testemail2');
INSERT INTO alter_proc_orders VALUES (1, 1, 1, 5, '2023-06-25'), (2, 1, 1, 6, '2023-06-25');
GO

CREATE PROCEDURE alter_proc_p1 
AS
    select * from alter_proc_users
GO

-- Test Case: Modify the procedure body
ALTER       -- test comment
    PROCEDURE alter_proc_p1
AS
    select * from alter_proc_orders
GO

create procedure alter_proc_p2
AS
    exec alter_proc_p1
go

create procedure alter_proc_p3 as select 1
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

create procedure alter_proc_p4 as select 1
go

-- Test Case: confirm information_schema.routines is updated properly with comments
alter 

/*
 * test comment 1
 */

-- test comment 2

procedure alter_proc_p4 as select 3
go

create function alter_proc_f1() 
returns int
AS BEGIN
    return 1
END

go

create procedure alter_proc_p5 as select 10
go

alter procedure alter_proc_p5 @dateParam date as select @dateParam
go