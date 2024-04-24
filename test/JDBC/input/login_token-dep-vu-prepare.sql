create database login_token_db;
go

use login_token_db;
go

create procedure login_token_proc as
	select count(*) from sys.login_token
go

create procedure user_token_proc as
	select count(*) from sys.user_token
go

create function login_token_func()
returns int
as
begin
	return(select count(*) from sys.login_token)
end
go

create function user_token_func()
returns int
as
begin
        return(select count(*) from sys.user_token)
end
go

create view login_token_view as
select count(*) from sys.login_token
go

create view user_token_view as
select count(*) from sys.user_token
go

