create procedure p_babel_1666 as
  declare @p1 decimal(5,2);
  set @p1 = 3.14;
  select @p1;
  return @p1;
go

declare @a decimal(5,2);
exec @a = p_babel_1666;
select @a;
go

declare @i int;
exec @i = p_babel_1666;
select @i;
go

drop procedure p_babel_1666
go
