use master;
go

create table t5548(a int);
insert into t5548 values (1);
go

select .a from t5548
go

select dbo..a from t5548
go

select ...a from .t5548
GO

select .t5548.a from t5548;
GO

select ..t5548.a from t5548;
go

select .dbo.t5548.a from t5548;
GO

drop table t5548;
go