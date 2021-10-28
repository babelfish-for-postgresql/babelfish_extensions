SELECT CONVERT(varchar(50), CAST($23.12 AS money), 0);
GO
SELECT CONVERT(varchar(50), CAST($23.12 AS money), 2);
GO
SELECT CONVERT(varchar(50), CAST($23.12 as money));
GO
SELECT CONVERT(float, CAST($23.12 as money));
GO
SELECT CONVERT(decimal, CAST($23.12 as money));
GO
SELECT CONVERT(numeric, CAST($23.12 as money));
GO
SELECT CONVERT(numeric(10,4), CAST($23.12 as money));
GO
declare @mon money;
set @mon = $23.12;
SELECT CONVERT(varchar(50), @mon);
GO
