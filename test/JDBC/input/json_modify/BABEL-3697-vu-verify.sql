SELECT * FROM babel_3697_1
GO

SELECT * FROM babel_3697_2
GO

SELECT * FROM babel_3697_3
GO

SELECT * FROM babel_3697_4
GO

SELECT * FROM babel_3697_5
GO

EXEC babel_3697_6
GO

EXEC babel_3697_7
GO

EXEC babel_3697_8
GO

SELECT * FROM babel_3697_multi_function
GO

select kk , dd, dbo.o7getcodevaluedesc() from (
   select a as kk, count(b) as dd from babel_4793  group by a 
) as drived
GO

select dbo.o7getcodevaluedesc() , kk , dd from (
   select a as kk, count(b) as dd from babel_4793  group by a 
) as drived
GO

select babel_4793_schema.babel_4793_func() , kk , dd from (
   select a as kk, count(b) as dd from babel_4793  group by a 
) as drived
GO

EXEC babel_4793_pro1
GO

EXEC babel_4793_pro2
GO

EXEC babel_4793_pro3
GO 