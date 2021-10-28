use master
go

create schema [Babelfish];
go

create type [Babelfish].[temp_type] from int;
go

declare @tint [Babelfish].[temp_type];
set @tint = 3;
print 'Value of variable is: ' + cast(@tint as varchar(5));
go

create type [Babelfish].[EmployeesType] as TABLE (first_name NVARCHAR(10), last_name NVARCHAR(10), emp_sal money);
go

declare @emps [Babelfish].[EmployeesType];
go

drop type [Babelfish].[temp_type];
go
drop type [Babelfish].[EmployeesType];
go
drop schema [Babelfish];
go
