create database alter_func_db;
go

use alter_func_db
go

CREATE TABLE alter_func_users ([Id] int, [firstname] varchar(50), [lastname] varchar(50), [email] varchar(50));
CREATE TABLE alter_func_orders ([Id] int, [userid] int, [productid] int, [quantity] int, [orderdate] Date);

INSERT INTO alter_func_users VALUES (1, 'j', 'o', 'testemail'), (2, 'e', 'l', 'testemail2');
INSERT INTO alter_func_orders VALUES (1, 1, 1, 5, '2023-06-25'), (2, 1, 1, 6, '2023-06-25');
GO

create function alter_func_mvu_f1() returns int begin return 2 end
go

alter function alter_func_mvu_f1(@param1 int) returns int begin return @param1 end
go

create function alter_func_mvu_f4() returns TABLE as return (select * from alter_func_users)
go

alter function alter_func_mvu_f4() returns TABLE as return (select * from alter_func_orders)
go

create function alter_func_mvu_f5() returns @result TABLE([Id] int) as begin insert @result select 1 return end
go

alter function alter_func_mvu_f5()
returns @result TABLE(Id int) as begin
insert into @result values (2)
return
end
go

use master;
go

CREATE database alter_proc_db
GO

use alter_proc_db
GO

CREATE PROCEDURE alter_proc_p1 
AS
    select * from alter_proc_users
GO

alter procedure alter_proc_p1 @dateParam date as select @dateParam
go

create procedure alter_proc_p3 as select 1
go

alter procedure alter_proc_p3 as select 4
GO
