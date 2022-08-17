-- test normal sp_executesql functionality
exec sp_executesql N'SELECT 1'
go

exec sp_executesql N'SELECT @var1', N'@var1 varchar(20)', @var1=2
go

exec sp_executesql N'SELECT @var1, @var2', N'@var1 int, @var2 varchar(20)', @var2='Hello, World!', @var1=123
go

exec sp_executesql N'SELECT @var1, @var2', N'@var1 int, @var2 varchar(20)', 123, 'Hello, World!'
go

-- these should all return no output
exec sp_executesql N''
go
exec sp_executesql N'', N''
go
exec sp_executesql N'', N'', N''
go
exec sp_executesql N'', N'', @var1=1
go

-- this should return 1
exec sp_executesql N'SELECT 1', N''
go

-- these should all return errors
-- error code 102
exec sp_executesql N'', N'@var1'
go

-- error code 8178
exec sp_executesql N'', N'@var1 varchar(20)'
go
