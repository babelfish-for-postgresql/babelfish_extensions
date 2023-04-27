create table babel2551_t1(a int);
create table babel2551_t2(a int);
go

BEGIN TRAN
insert babel2551_t1 values (1), (1), (3), (null);
insert into babel2551_t2 select top(3) a from babel2551_t1 order by 1;
select * from babel2551_t2 order by 1;
ROLLBACK
GO

BEGIN TRAN
insert babel2551_t1 values (1), (1), (1), (1), (2);
insert into babel2551_t2 select distinct top(2) a from babel2551_t1 order by 1;
select * from babel2551_t2 order by 1;
ROLLBACK
GO

BEGIN TRAN
insert babel2551_t1 values (1), (2), (3), (4);
insert top(2) into babel2551_t2 select top(3) a from babel2551_t1 order by 1;
select * from babel2551_t2 order by 1;
ROLLBACK
GO

BEGIN TRAN
insert babel2551_t1 values (1), (2), (3), (4);
insert into babel2551_t2 select top(2) s.a from (select top(3) a from babel2551_t1 order by 1) s order by 1;
select * from babel2551_t2 order by 1;
ROLLBACK
GO

BEGIN TRAN
insert babel2551_t1 values (1), (2), (3), (4);
insert into babel2551_t2 select top(2) a from babel2551_t1 where a in (select top(3) a from babel2551_t1 order by 1) order by 1;
select * from babel2551_t2 order by 1;
ROLLBACK
GO

BEGIN TRAN
insert babel2551_t1 values (1), (2), (3), (4);
insert babel2551_t2 values (2), (3), (4), (5);
insert into babel2551_t2 select top(2) t1.a from babel2551_t1 t1 join babel2551_t2 t2 on t1.a = t2.a order by 1;
select * from babel2551_t2 order by 1;
ROLLBACK
GO

BEGIN TRAN
insert babel2551_t1 values (1), (2), (3), (4);
insert babel2551_t2 values (2), (3), (4), (5);
insert into babel2551_t2 select distinct top(2) t1.a from babel2551_t1 t1 cross join babel2551_t2 t2 order by t1.a;
select * from babel2551_t2 order by 1;
ROLLBACK
GO

BEGIN TRAN
insert babel2551_t1 values (1), (2), (3), (4);
insert into babel2551_t2 select top(2) t1.a into babel2551_t3 from babel2551_t1;
ROLLBACK
GO

create view babel2551_view as select a from babel2551_t1;
GO

BEGIN TRAN
insert babel2551_t1 values (1), (2), (3), (4);
insert into babel2551_t2 select top(3) a from babel2551_view order by 1;
select * from babel2551_t2 order by 1;
ROLLBACK
GO

drop view babel2551_view
GO

create function babel2551_cross_appy_func(@a int) returns @ret table(a int) as
BEGIN
    insert into @ret select top(1) a from babel2551_t1 where a = @a
    return
END;
GO

BEGIN TRAN
insert babel2551_t1 values (1), (2), (3), (4);
insert babel2551_t2 values (2), (3), (4), (5);
insert into babel2551_t2 select top(2) t1.a
from babel2551_t1 t1 cross apply babel2551_cross_appy_func(t1.a);
select * from babel2551_t2 order by 1;
ROLLBACK
GO

drop function babel2551_cross_appy_func;
GO

drop table babel2551_t1;
drop table babel2551_t2;
GO

declare @2551_top_const INT = 2;
declare @2551_tbl_var as table (a VARCHAR(15));
insert into @2551_tbl_var values ('a'), ('b'), ('c'), ('d')
insert into  @2551_tbl_var select top(@2551_top_const) tbl.a from @2551_tbl_var tbl;
select * from @2551_tbl_var order by a;
GO

-- BABEL-3312 Case
CREATE TABLE babel2551_t1(c1 int, c2 int)
CREATE TABLE babel2551_t2(c1 int, c2 int, c3 int)
GO
INSERT INTO babel2551_t1(c1, c2) VALUES(1, 10)
INSERT INTO babel2551_t1(c1, c2) VALUES(2, 20)
INSERT INTO babel2551_t2(c1, c2, c3) VALUES(1, 1, 100)
INSERT INTO babel2551_t2(c1, c2, c3) VALUES(1, 2, 1001)
GO

--Multi-statement function with TOP
CREATE FUNCTION myMSTVF(@a int)
RETURNS @ret table (a int)
AS
BEGIN
INSERT INTO @ret
SELECT TOP(2) c1
FROM babel2551_t2
WHERE babel2551_t2.c1 = @a
RETURN
END
GO

SELECT * FROM babel2551_t1 CROSS APPLY myMSTVF(babel2551_t1.c1)
GO

SELECT * FROM myMSTVF(1)
GO

DROP FUNCTION myMSTVF
DROP TABLE babel2551_t1
DROP TABLE babel2551_t2
GO
