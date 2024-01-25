sp_describe_undeclared_parameters N'SELECT @p1', NULL
GO

sp_describe_undeclared_parameters N'SELECT @p1', 1
GO

sp_describe_undeclared_parameters N'SELECT @p1', N'text_test'
GO

sp_describe_undeclared_parameters N'SELECT * FROM t1'
GO

sp_describe_undeclared_parameters N'SELECT COUNT(*) FROM sys.assemblies'
GO
