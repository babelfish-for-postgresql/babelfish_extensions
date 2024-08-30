select * from babel_5179_v1
go

select babel_5179_f1()
go

exec babel_5179_p1
go

select * from babel_5179_v2
go

select * from babel_5179_v11
go

select * from babel_5179_v22
go

SELECT * FROM babel_5179_f2();
go

exec babel_5179_p2
go

select col2 from babel_5179_t1 order by col2;
go

select col2 from babel_5179_t2 order by col2;
go

insert into babel_5179_t1 values ('13:42:31.321');
insert into babel_5179_t1 values ('13:42:31.32');
insert into babel_5179_t1 values ('13:42:31.3');
go

insert into babel_5179_t2 values ('13:42:31.321');
insert into babel_5179_t2 values ('13:42:31.32');
insert into babel_5179_t2 values ('13:42:31.3');
go

select cast(cast('12:45:37.123' as varchar) as time);
go

select cast(cast('12:45:37.12' as varchar) as time);
go

select cast(cast('12:45:37.1' as varchar) as time);
go

select cast(cast('12:45:37.123' as varchar) as time(2));
go

select cast(cast('12:45:37.12' as varchar) as time(2));
go

select cast(cast('12:45:37.1' as varchar) as time(2));
go

select cast((select top 1 col1 from babel_5179_t1 order by col2) as time);
go

select cast((select top 1 col1 from babel_5179_t2 order by col2) as time);
go

select cast((select top 1 col1 from babel_5179_t1 order by col2) as time(2));
go

select cast((select top 1 col1 from babel_5179_t2 order by col2) as time(2));
go

-- maxscale tests
select cast((select top 1 col1 from babel_5179_t1 order by col2) as time(7));
go

select cast((select top 1 col1 from babel_5179_t2 order by col2) as time(7));
go

select cast(cast('12:45:37.123' as varchar) as time(7));
go

select cast(cast('12:45:37.12345678324567898776455678978765465768798676578796756568976875467586978675645789707867565789786756547897867' as varchar) as time(7));
go

select cast(cast('12:45:37.1' as varchar) as time(7));
go

-- negative tests
select cast((select top 1 col1 from babel_5179_t1 order by col2) as time(10));
go

select cast((select top 1 col1 from babel_5179_t2 order by col2) as time(10));
go

select cast(cast('12:45:37.123' as varchar) as time(10));
go

select cast(cast('12:45:37.12' as varchar) as time(10));
go

select cast(cast('12:45:37.1' as varchar) as time(10));
go
