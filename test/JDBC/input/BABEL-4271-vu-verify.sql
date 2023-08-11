-- Test to check ESCAPE null case (ESCAPE null means no ESCAPE char used)
select 1 where 'ABCD' LIKE 'AB[C]D' ESCAPE '';
go
select 1 where 'cbc' LIKE '[c-a]bc' ESCAPE '';
go
select 1 where 'abc' LIKE '[0-a]bc' ESCAPE '';
go
select 1 where 'abc' LIKE '[abc]bc' ESCAPE '';
go
select 1 where 'abc' LIKE '[a-c]bc' ESCAPE '';
go
select 1 where 'bbc' LIKE '[a-c]bc' ESCAPE '';
go
select a, b from testvikasprj where testvikasprj.a LIKE testvikasprj.b ESCAPE '';
go
-- Test to check ESCAPE null case (ESCAPE null means no ESCAPE char used)
select 1 where 'ABCD' LIKE 'AB[C]D' ESCAPE null;
go
select 1 where 'cbc' LIKE '[c-a]bc' ESCAPE null;
go
select 1 where 'abc' LIKE '[0-a]bc' ESCAPE null;
go
select 1 where 'abc' LIKE '[abc]bc' ESCAPE null;
go
select 1 where 'abc' LIKE '[a-c]bc' ESCAPE null;
go
select 1 where 'bbc' LIKE '[a-c]bc' ESCAPE null;
go
select a, b from testvikasprj where testvikasprj.a LIKE testvikasprj.b ESCAPE null;
go