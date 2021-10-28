create table t_babel_1241 (a int, b int);
insert into t_babel_1241 values (10, 1);
go

declare @v int=1;
select @v+=a from t_babel_1241;
select @v
go

declare @v int=11;
select @v-=a from t_babel_1241;
select @v;
go

declare @v int=2;
select @v*=a from t_babel_1241;
select @v;
go

declare @v int=20;
select @v/=a from t_babel_1241;
select @v;
go

declare @v int=24;
select @v%=a from t_babel_1241;
select @v;
go

declare @v int=63;
select @v&=a from t_babel_1241;
select @v;
go

declare @v int=7;
select @v|=a from t_babel_1241;
select @v;
go

declare @v int=7;
select @v^=a from t_babel_1241;
select @v;
go

-- many compound operator
declare @v int=1;
declare @v2 int=2;
declare @v3 int=3;
select @v+=a, @v2-=a, @v3*=a from t_babel_1241;
select @v, @v2, @v3;
go

-- compound operator on same target (we don't support this)
declare @v int=1;
select @v+=a, @v-=b from t_babel_1241;
select @v
go

-- compound operator and equal operator
declare @v int=1;
declare @v2 int=2;
select @v+=a, @v2=b from t_babel_1241;
select @v, @v2;
go

-- compound operator and non-assignment. error should be thrown
declare @v int=1;
declare @v2 int=2;
select @v+=a, b from t_babel_1241;
go

drop table t_babel_1241;
go
