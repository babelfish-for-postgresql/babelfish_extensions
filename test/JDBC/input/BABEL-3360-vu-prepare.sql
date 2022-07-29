create view BABEL_3360_vu_prepare_v1 as (select dateadd(millisecond, 56, cast('2016-12-26 23:29:29' as datetime2)));
go
select * from BABEL_3360_vu_prepare_v1;
go

create view BABEL_3360_vu_prepare_v2 as (select dateadd(microsecond, 56, cast('2016-12-26 23:29:29' as datetime2)));
go
select * from BABEL_3360_vu_prepare_v2;
go

create view BABEL_3360_vu_prepare_v3 as (select dateadd(millisecond, 56, null));
go
select * from BABEL_3360_vu_prepare_v3;
go

create view BABEL_3360_vu_prepare_v4 as (select dateadd(microsecond, 56, null));
go
select * from BABEL_3360_vu_prepare_v4;
go