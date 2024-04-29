-- tsql
use login_token_db;
go

exec login_token_proc;
go

select login_token_func();
go

select * from login_token_view;
go

exec user_token_proc;
go

select user_token_func();
go

select * from user_token_view;
go

