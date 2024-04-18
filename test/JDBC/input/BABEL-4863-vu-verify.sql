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
select 1[c];
GO
select 1'c';
GO
select 1"c";
GO
select 'abc'[def];
GO
select 'abc''def';
GO
select 'abc'"def";
GO
select 123[this is a $.^ test]
GO
select 123'this is a $.^ test'
GO
select 123"this is a $.^ test"
GO
SELECT CASE WHEN 1=1  THEN 1 ELSE 0 END[this is a $.^ test]
GO
SELECT CASE WHEN 1=1  THEN 1 ELSE 0 END'this is a $.^ test'
GO
SELECT CASE WHEN 1=1  THEN 1 ELSE 0 END"this is a $.^ test"
GO
select * from babel_4863_func1();
GO
exec babel_4863_proc 1;
GO
exec babel_4863_proc 2;
GO
SELECT * FROM babel_4863_view;
GO
