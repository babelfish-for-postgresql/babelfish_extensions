CREATE TABLE dbo.t2936 (c XML NULL);
go

exec sp_describe_undeclared_parameters N'INSERT INTO [dbo].[t2936]([c]) values (@P1)'
go

DROP TABLE dbo.t2936;
go
