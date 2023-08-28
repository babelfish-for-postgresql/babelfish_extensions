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
select a, b from babel_4271_vu_prepare_t1 where babel_4271_vu_prepare_t1.a LIKE babel_4271_vu_prepare_t1.b ESCAPE '';
go
SELECT a, '' from babel_4271_vu_prepare_t1 where babel_4271_vu_prepare_t1.a LIKE '' ESCAPE '';
go
SELECT a, 'abc' from babel_4271_vu_prepare_t1 where babel_4271_vu_prepare_t1.a LIKE '' ESCAPE '';
go
SELECT '', '' from babel_4271_vu_prepare_t1 where '' LIKE babel_4271_vu_prepare_t1.b ESCAPE '';
go
SELECT 'xy', b from babel_4271_vu_prepare_t1 where 'cbc' LIKE babel_4271_vu_prepare_t1.a ESCAPE '';
go
SELECT a, b from babel_4271_vu_prepare_t1 where '' LIKE '' ESCAPE '';
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
select a, b from babel_4271_vu_prepare_t1 where babel_4271_vu_prepare_t1.a LIKE babel_4271_vu_prepare_t1.b ESCAPE null;
go
SELECT a, 'abc' from babel_4271_vu_prepare_t1 where babel_4271_vu_prepare_t1.a LIKE 'abc' ESCAPE null;
go
SELECT a, '' from babel_4271_vu_prepare_t1 where babel_4271_vu_prepare_t1.a LIKE babel_4271_vu_prepare_t1.b ESCAPE null;
go
SELECT a, '' from babel_4271_vu_prepare_t1 where babel_4271_vu_prepare_t1.a LIKE '' ESCAPE null;
go
SELECT 'xy', b from babel_4271_vu_prepare_t1 where 'cbc' LIKE babel_4271_vu_prepare_t1.a ESCAPE null;
go
SELECT '', '' from babel_4271_vu_prepare_t1 where '' LIKE babel_4271_vu_prepare_t1.b ESCAPE null;
go
SELECT a, b from babel_4271_vu_prepare_t1 where '' LIKE '' ESCAPE null;
go