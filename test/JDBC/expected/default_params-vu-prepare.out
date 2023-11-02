create function default_params_func1 (@p1 int=1,@p2 int = 2 ) returns int as begin return @p1 + @p2 end;
GO

create function default_params_func2 (@p1 int,@p2 int =2, @p3 int) returns int as begin return @p1 + @p2 + @p3 end;
GO

create function default_params_func3 (@p1 varchar(20) = 'abc') returns varchar as begin return @p1 end;
GO

create proc default_params_proc1 @p1 int=1, @p2 int=2, @p3 int=3 as select @p1, @p2, @p3
GO


create proc default_params_proc2 (@p1 varchar(20) = 'abc', @p2 int) as select @p1, @p2
GO

create proc default_params_proc3 (@p1 varchar = 'abc', @p2 int) as select @p1, @p2
GO

create proc default_params_proc4 @p1 int=1, @p2 int=2, @p3 varchar(20)='dbb' as select @p1, @p2, @p3
GO
