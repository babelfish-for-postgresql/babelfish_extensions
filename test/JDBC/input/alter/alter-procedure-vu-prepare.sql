CREATE TABLE alter_proc_users ([Id] int, [firstname] varchar(50), [lastname] varchar(50), [email] varchar(50));
CREATE TABLE alter_proc_orders ([Id] int, [userid] int, [productid] int, [quantity] int, [orderdate] Date);

INSERT INTO alter_proc_users VALUES (1, 'j', 'o', 'testemail'), (1, 'e', 'l', 'testemail2');
INSERT INTO alter_proc_orders VALUES (1, 1, 1, 5, '2023-06-25'), (2, 1, 1, 6, '2023-06-25');
GO

CREATE PROCEDURE alter_proc_p1 
AS
    select * from alter_proc_users
GO

create procedure alter_proc_p2
AS
    exec alter_proc_p1
go

create procedure alter_proc_p3 as select 1
go

create function alter_proc_f1() 
returns int
AS BEGIN
    return 1
END

go