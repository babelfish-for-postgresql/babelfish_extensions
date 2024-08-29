select * from babel_5179_v1
go
~~START~~
time
12:45:37.1230000
~~END~~


select babel_5179_f1()
go
~~START~~
time
12:45:37.1230000
~~END~~


exec babel_5179_p1
go
~~START~~
time
12:45:37.1230000
~~END~~


select * from babel_5179_v2
go
~~START~~
time
12:45:37.12
~~END~~


select babel_5179_f2()
go
~~START~~
time
12:45:37.1200000
~~END~~


exec babel_5179_p2
go
~~START~~
time
12:45:37.12
~~END~~


select col2 from babel_5179_t1 order by col2;
go
~~START~~
time
12:45:37.1000000
12:45:37.1200000
12:45:37.1230000
~~END~~


select col2 from babel_5179_t2 order by col2;
go
~~START~~
time
12:45:37.1000000
12:45:37.1200000
12:45:37.1230000
~~END~~


select cast(cast('12:45:37.123' as varchar) as time);
go
~~START~~
time
12:45:37.1230000
~~END~~


select cast(cast('12:45:37.12' as varchar) as time);
go
~~START~~
time
12:45:37.1200000
~~END~~


select cast(cast('12:45:37.1' as varchar) as time);
go
~~START~~
time
12:45:37.1000000
~~END~~


select cast(cast('12:45:37.123' as varchar) as time(2));
go
~~START~~
time
12:45:37.12
~~END~~


select cast(cast('12:45:37.12' as varchar) as time(2));
go
~~START~~
time
12:45:37.12
~~END~~


select cast(cast('12:45:37.1' as varchar) as time(2));
go
~~START~~
time
12:45:37.10
~~END~~


select cast((select top 1 col1 from babel_5179_t1 order by col2) as time);
go
~~START~~
time
12:45:37.1000000
~~END~~


select cast((select top 1 col1 from babel_5179_t2 order by col2) as time);
go
~~START~~
time
12:45:37.1000000
~~END~~


select cast((select top 1 col1 from babel_5179_t1 order by col2) as time(2));
go
~~START~~
time
12:45:37.10
~~END~~


select cast((select top 1 col1 from babel_5179_t2 order by col2) as time(2));
go
~~START~~
time
12:45:37.10
~~END~~


-- maxscale tests
select cast((select top 1 col1 from babel_5179_t1 order by col2) as time(7));
go
~~START~~
time
12:45:37.100000
~~END~~


select cast((select top 1 col1 from babel_5179_t2 order by col2) as time(7));
go
~~START~~
time
12:45:37.100000
~~END~~


select cast(cast('12:45:37.123' as varchar) as time(7));
go
~~START~~
time
12:45:37.123000
~~END~~


select cast(cast('12:45:37.12345678324567898776455678978765465768798676578796756568976875467586978675645789707867565789786756547897867' as varchar) as time(7));
go
~~START~~
time
12:45:37.123457
~~END~~


select cast(cast('12:45:37.1' as varchar) as time(7));
go
~~START~~
time
12:45:37.100000
~~END~~


-- negative tests
select cast((select top 1 col1 from babel_5179_t1 order by col2) as time(10));
go
~~ERROR (Code: 33557097)~~

~~ERROR (Message: Specified scale 10 is invalid. 'time' datatype must have scale between 0 and 7)~~


select cast((select top 1 col1 from babel_5179_t2 order by col2) as time(10));
go
~~ERROR (Code: 33557097)~~

~~ERROR (Message: Specified scale 10 is invalid. 'time' datatype must have scale between 0 and 7)~~


select cast(cast('12:45:37.123' as varchar) as time(10));
go
~~ERROR (Code: 33557097)~~

~~ERROR (Message: Specified scale 10 is invalid. 'time' datatype must have scale between 0 and 7)~~


select cast(cast('12:45:37.12' as varchar) as time(10));
go
~~ERROR (Code: 33557097)~~

~~ERROR (Message: Specified scale 10 is invalid. 'time' datatype must have scale between 0 and 7)~~


select cast(cast('12:45:37.1' as varchar) as time(10));
go
~~ERROR (Code: 33557097)~~

~~ERROR (Message: Specified scale 10 is invalid. 'time' datatype must have scale between 0 and 7)~~

