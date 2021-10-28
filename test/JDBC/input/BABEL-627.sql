USE master;
GO

-- run built-in functions with master dbo
select dateadd(year, 2, CAST('20060830' AS datetime));
GO
select datediff(year, CAST('2037-03-01 23:30:05.523' AS datetime), CAST('2036-02-28 23:30:05.523' AS datetime));
GO
select datepart(week, CAST('2007-04-21' AS date)), datepart(weekday, CAST('2007-04-21' AS date));
GO
