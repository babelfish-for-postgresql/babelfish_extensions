-- [BABEL-1528] CASTing a DATE literal without time part to TIME datatype should not fail
create table BABEL_1528_vu_prepare_t1(a time)
GO

insert into BABEL_1528_vu_prepare_t1 values ('2012-02-23')
GO

create view BABEL_1528_vu_prepare_v1 as select CAST('2012-02-23' AS time) as val
GO

create procedure BABEL_1528_vu_prepare_p1 as select CAST('2012-02-23' AS time) as val
GO

create function BABEL_1528_vu_prepare_f1()
returns time
as
begin
	return (select CAST('2012-02-23' AS time) as val)
end
GO
