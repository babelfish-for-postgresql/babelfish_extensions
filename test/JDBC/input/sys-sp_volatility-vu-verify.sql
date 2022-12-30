exec sys.sp_volatility 'f1'
go
exec sys.sp_volatility 'f1', 'stable'
go
exec sys.sp_volatility 'f1'
go
exec sys.sp_volatility 'f1', 'immutable'
go
exec sys.sp_volatility 'f1'
go
exec sys.sp_volatility 'f1', 'volatile'
go
exec sys.sp_volatility 'f1'
go
exec sys.sp_volatility 'f1', 'random'
go
exec sys.sp_volatility 'f1'
go

exec sys.sp_volatility 'a.f1'
go
exec sys.sp_volatility 'a.f1', 'stable'
go
exec sys.sp_volatility 'a.f1'
go
exec sys.sp_volatility 'a.f1', 'immutable'
go
exec sys.sp_volatility 'a.f1'
go
exec sys.sp_volatility 'a.f1', 'volatile'
go
exec sys.sp_volatility 'a.f1'
go
exec sys.sp_volatility 'a.f1', 'random'
go
exec sys.sp_volatility 'a.f1'
go

/* should give error as only schema.function_name is supported*/
exec sys.sp_volatility 'master.a.f1'
go

exec sys.sp_volatility 'random_function'
go

exec sys.sp_volatility '','stable'
go
