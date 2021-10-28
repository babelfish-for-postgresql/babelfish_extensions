create table employees(@pers_id int, @fname nvarchar(20), @lname nvarchar(30), sal money)
GO

create procedure p_employee_select as begin select * from employees end
GO

call p_employee_select
GO

call p_employee_select
GO

create procedure p as select 2; select 1;
go
execute p;
go

drop procedure p_employee_select, p;
drop table employees;
go
