create table t_babel_2049 (a int, b int);
insert into t_babel_2049 values (10, 1);
go

declare @v int=1;
set @v+=10
select @v
go

declare @v int=11;
set @v-=10;
select @v;
go

declare @v int=2;
set @v*=10;
select @v;
go

declare @v int=20;
set @v/=10;
select @v;
go

declare @v int=24;
set @v%=10;
select @v;
go

declare @v int=63;
set @v&=10;
select @v;
go

declare @v int=7;
set @v|=10;
select @v;
go

declare @v int=7;
set @v^=10;
select @v;
go

declare @a int=-10;
declare @v int=1;
set @v+=abs(@a)
select @v
go

declare @v int=1;
set @v+=-10;
select @v
go

declare @v int=1;
set @v+=+10;
select @v
go

drop table t_babel_2049;
go
