select 1 where 'ABCD' LIKE 'AB[C]D' ESCAPE ''
go
select 1 where 'cbc' LIKE '[c-a]bc' ESCAPE ''
go
select 1 where 'abc' LIKE '[0-a]bc' ESCAPE ''
go
select 1 where 'abc' LIKE '[abc]bc' ESCAPE ''
go
select 1 where 'abc' LIKE '[a-c]bc' ESCAPE ''
go
select 1 where 'bbc' LIKE '[a-c]bc' ESCAPE ''
go
--Queries that cover the ESCAPE null case (ESCAPE null means no ESCAPE char used)
select 1 where 'ABCD' LIKE 'AB[C]D' ESCAPE null
go
select 1 where 'cbc' LIKE '[c-a]bc' ESCAPE null
go
select 1 where 'abc' LIKE '[0-a]bc' ESCAPE null
go
select 1 where 'abc' LIKE '[abc]bc' ESCAPE null
go
select 1 where 'abc' LIKE '[a-c]bc' ESCAPE null
go
select 1 where 'bbc' LIKE '[a-c]bc' ESCAPE null
go