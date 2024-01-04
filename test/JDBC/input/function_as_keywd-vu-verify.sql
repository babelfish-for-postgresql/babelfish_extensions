create function f1_function_as_keywd () returns tinyint begin return 1 end
go
select dbo.f1_function_as_keywd()
go

create function f2_function_as_keywd () returns tinyint as begin return 2 end
go
select dbo.f2_function_as_keywd()
go

create function f3_function_as_keywd () returns int
begin return 3 end
go
select dbo.f3_function_as_keywd()
go

create function f4_function_as_keywd () returns tinyint
as begin return 4 end
go
select dbo.f4_function_as_keywd()
go

execute('create function f5_function_as_keywd () returns tinyint begin return 5 end')
go
select dbo.f5_function_as_keywd()
go
