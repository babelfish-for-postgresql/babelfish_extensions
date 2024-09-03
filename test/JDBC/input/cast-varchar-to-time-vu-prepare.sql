create view babel_5179_v1 as select cast(cast('12:45:37.123' as varchar) as time)
go

create table babel_5179_t1(col1 varchar(50), col2 as cast(col1 as time), constraint timecmp check(col1 >= '12:45:37.1'));
go

insert into babel_5179_t1 values ('12:45:37.123');
insert into babel_5179_t1 values ('12:45:37.12');
insert into babel_5179_t1 values ('12:45:37.1');
go

create view babel_5179_v11 as select col1, col2 from babel_5179_t1;
go

create function babel_5179_f1() returns table 
as return (
    select cast(cast('12:45:37.123' as varchar) as time)
)
go

create procedure babel_5179_p1 as select cast(cast('12:45:37.123' as varchar) as time)
go

create view babel_5179_v2 as select cast(cast('12:45:37.123' as varchar) as time(2))
go

create table babel_5179_t2(col1 varchar(50), col2 as cast(col1 as time(2)), constraint timecmp check(col1 >= '12:45:37.1'));
go

insert into babel_5179_t2 values ('12:45:37.123');
insert into babel_5179_t2 values ('12:45:37.12');
insert into babel_5179_t2 values ('12:45:37.1');
go

create view babel_5179_v22 as select col1, col2 from babel_5179_t2;
go

CREATE FUNCTION babel_5179_f2() 
RETURNS @ResultTable TABLE (result TIME(2)) 
AS 
BEGIN 
INSERT INTO @ResultTable SELECT CAST(CAST('12:45:37.123' AS VARCHAR) AS TIME(2));
RETURN; 
END;
go

create procedure babel_5179_p2 as select cast(cast('12:45:37.123' as varchar) as time(2))
go