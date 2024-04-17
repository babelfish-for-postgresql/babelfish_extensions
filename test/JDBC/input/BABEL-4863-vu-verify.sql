SELECT 123abc;
GO
SELECT 0x0o;
GO
SELECT 1_2_3;
GO
SELECT 0.a;
GO
SELECT 0.0a;
GO
SELECT .0a;
GO
SELECT 0.0e1a;
GO
SELECT 0.0e;
GO
SELECT 0.0e+a;
GO
SELECT $1a;
GO
SELECT CASE WHEN 1=1  THEN 1 ELSE 0 END[c]
GO
SELECT CASE WHEN 1=1  THEN 1 ELSE 0 END'c'
GO
SELECT CASE WHEN 1=1  THEN 1 ELSE 0 END"c"
GO
select a[c] from babel_4863_t1
GO
select a"c" from babel_4863_t1
GO
select a'c' from babel_4863_t1
GO
declare @v int=1
select @v[c]
GO
declare @v int=1
select @v'c'
GO
declare @v int=1
select @v"c"
GO
select babel_4863_func()[a];
GO
