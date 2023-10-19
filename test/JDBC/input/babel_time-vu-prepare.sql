create table babel_time_vu_prepare_t1(a time)
GO

insert into babel_time_vu_prepare_t1 values ('2012-02-23')
GO

create view babel_time_vu_prepare_v1 as select CAST('2012-02-23' AS time) as val
GO

create procedure babel_time_vu_prepare_p1 as select CAST('2012-02-23' AS time) as val
GO

create function babel_time_vu_prepare_f1()
returns time
as
begin
	return (select CAST('2012-02-23' AS time) as val)
end
GO
