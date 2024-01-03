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

-- it'll use default 
select default_params_func4(default);
GO

select default_params_func5(default);
GO

exec default_params_proc1 111, default, 333
GO

exec default_params_proc1 default, default, default
GO

exec default_params_proc1 default
GO

exec default_params_proc1 @p1=default, @p2=default,@p3=300
GO

exec default_params_proc1 @p1=300, @p2=default,@p3=default
GO

exec default_params_proc1 @p1=default, @p2=300,@p3=default
GO

exec default_params_proc2 default, 2
GO

exec default_params_proc2 'dddd', 2
GO

exec default_params_proc3 default, 2
GO

exec default_params_proc3 'dddd', 3
GO

-- verify the error message
exec default_params_proc3 default, default
GO

-- verify the error message
exec default_params_proc3 'ddd', default
GO

-- verify the type cast
exec default_params_proc4 1,2,default
GO

exec default_params_proc4 1,2, @p3=default
GO
