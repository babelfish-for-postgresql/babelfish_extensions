select default_params_func1(default, default);
GO

select default_params_func1(10, default);
GO

select default_params_func1(10);
GO

select default_params_func1();
GO

select default_params_func1(default);
GO

select default_params_func2(10,default,20);
GO

select default_params_func2(10,20,30);
GO

select default_params_func3(default);
go

select default_params_func3();
GO

select default_params_func3('dddd');
GO

exec default_params_proc1 111, default, 333
GO

exec default_params_proc1 default, default, default
GO

exec default_params_proc1 default
GO

exec default_params_proc2 default, 2
GO

exec default_params_proc2 'dddd', 2
GO

exec default_params_proc3 default, 2
GO

exec default_params_proc3 'dddd', 3
GO

exec default_params_proc4 1,2,default
GO
