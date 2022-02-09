-- WITH clause and INSERT statement
CREATE TABLE t1 ( a int, b int);
GO

CREATE PROC p1 AS
WITH cte AS
(
SELECT 1, 2
)
INSERT INTO t1 SELECT * from cte;
GO

EXEC p1;
GO

SELECT * from t1
GO

-- WITH clause and DELETE statement
create table t5 ( a int, b int);
go
insert into t5 values (1, 2);
go
select * from t5;
go
create proc p3 as
with cte as
(
select 1 as 'a', 10 as 'b'
)
delete from t5 where t5.a = (select cte.a from cte);
go

EXEC p3
GO

SELECT * from t5;
GO

-- WITH clause and SELECT INTO (implicit temp table creation)
create proc p4 as
with cte as
(
select 1 as c1, 2 as c2
)
select * INTO #tt from cte
select * from #tt
GO

EXEC p4
GO

-- WITH clause and SELECT assign
create proc p5 as
declare @a int;
declare @b int;
with cte as
(
select 1 as c1, 2 as c2
)
select @a = c1 , @b = c2 from cte
select @a
select @b
go

EXEC p5
GO

DROP TABLE t1
DROP TABLE t5
DROP PROCEDURE p1
DROP PROCEDURE p3
DROP PROCEDURE p4
DROP PROCEDURE p5
GO
