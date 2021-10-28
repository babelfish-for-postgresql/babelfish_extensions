USE master
GO

create table [dbo].[t23]([id] int, [a] money, [b] datetime)
go

exec sp_describe_undeclared_parameters
N'INSERT INTO [dbo].[t23]([id],[a],[b]) values (@P1,@P2,@P3)'
go

-- cleanup
drop table [dbo].[t23];
go
