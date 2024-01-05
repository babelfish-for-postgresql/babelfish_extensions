select 2E
go

select -2E
go

select +2E
go

select 2.1E
go

select -2.1E
go

select +2.1E
go

select 2.e
go

select -2.e
go

select +2.e
go

select .2e
go

select -.2E
go

select +.2E
go

select .2E+
go

select .2E-
go

select 2E+
go

select 2E-
go

select +.2E+
go

select -.2E-
go

select -.2E-1
go

-- 2 + 1 = 3
select 2E +1
go

-- 2 + 1 = 3
select 2E+ +1
go

-- string constant, no change:
select '2E'
go

-- hex constant: no change
select 0xe
go

-- invalid syntax in SQL Server
select 2E+ 1
go

-- invalid syntax in SQL Server
select 2 E+1
go

-- invalid syntax in SQL Server
select 2 E+
go

-- not a number but parsed as identifier
select .e
go

-- not a number
select 1.2.e
go

insert t1_float_exponent values (2e+, 3.1e, -.4e-, 5.e-) 
select * from t1_float_exponent
go
delete t1_float_exponent
go

exec p1_float_exponent 2E
go

exec p1_float_exponent 2E+
go

exec p1_float_exponent -.2E+
go

exec p1_float_exponent @p=-.2E+
go

p1_float_exponent 2E
go

p1_float_exponent 2E+
go

p1_float_exponent -.2E+
go

p1_float_exponent @p=-.2E+
go

exec p2_float_exponent
select * from t1_float_exponent
go

select * from v1_float_exponent
go

select dbo.f1_float_exponent(2e)
go

select dbo.f1_float_exponent(-.2e-)
go

select dbo.f1_float_exponent(+2.e-)
go

-- JDBC test cases do not capture PRINT output, so the following tests have been commented out - but they work!

-- print string '2e' (no change):
--print '2E'
--go

-- print 2:
--print 2E
--go

-- print -0.2:
--print -.2E
--go

-- print -0.2:
--print -.2E+
--go

-- print 0.2:
--print +.2E-
--go

