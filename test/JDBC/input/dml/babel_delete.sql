-------------------------------------------------------------
-- BABEL-2020
-------------------------------------------------------------
drop procedure if exists babel_2020_delete_ct;
go

create procedure babel_2020_delete_ct as
begin
    drop table if exists babel_2020_delete_t1
    create table babel_2020_delete_t1 (a int)
    insert into babel_2020_delete_t1 values (1), (2), (NULL)
    drop table if exists babel_2020_delete_t2
    create table babel_2020_delete_t2 (a int)
    insert into babel_2020_delete_t2 values (2), (3), (NULL)
end
go

-- single tables in FROM clause
exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x;
go

exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x where x.a = 2;
go

-- multiple tables in FROM clause
exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x, babel_2020_delete_t2 y;
go

exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x, babel_2020_delete_t2 y where x.a = 2;
go

exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x, babel_2020_delete_t2 y where y.a = 2;
go

exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x, babel_2020_delete_t2 y where x.a = y.a;
go

-- JOIN clause
exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x join babel_2020_delete_t2 y on 1 = 1;
go

exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x join babel_2020_delete_t2 y on x.a = 2;
go

exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x join babel_2020_delete_t2 y on y.a = 2;
go

exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x join babel_2020_delete_t2 y on x.a = y.a;
go

-- subqueries
exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from (select * from babel_2020_delete_t1) x;
go

exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x, (select * from babel_2020_delete_t1) y;
go

-- self join
exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x, (select * from babel_2020_delete_t1) y where x.a + 1 = y.a;
go

exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 y, (select * from babel_2020_delete_t1) x where x.a + 1 = y.a;
go

exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x join babel_2020_delete_t1 on babel_2020_delete_t1.a + 1 = x.a;
go

exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 join babel_2020_delete_t1 x on babel_2020_delete_t1.a + 1 = x.a;
go

exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x, babel_2020_delete_t1 y where x.a + 1 = y.a;
go

-- outer joins
exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x left outer join babel_2020_delete_t2 on babel_2020_delete_t2.a = x.a;
go

exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t2 left outer join babel_2020_delete_t1 x on babel_2020_delete_t2.a = x.a;
go

-- null filters
exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x where x.a is null;
go

exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t2 left outer join babel_2020_delete_t1 x on x.a is null;
go

-- updatable views
drop view if exists babel_2020_delete_v1;
go

exec babel_2020_delete_ct;
go

create view babel_2020_delete_v1 as select * from babel_2020_delete_t1 where babel_2020_delete_t1.a is not null;
go

delete babel_2020_delete_v1 from babel_2020_delete_v1 x where x.a = 2;
go

drop view if exists babel_2020_delete_v1;
go

-- semi joins
exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x where x.a in (select a from babel_2020_delete_t1 where babel_2020_delete_t1.a = x.a);
go

exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x where not exists (select a from babel_2020_delete_t1 y where y.a + 1 = x.a);
go

exec babel_2020_delete_ct;
delete babel_2020_delete_t1 from babel_2020_delete_t1 x where exists (select a from babel_2020_delete_t1 y where y.a + 1 = x.a);
go

drop procedure if exists babel_2020_delete_ct;
drop table if exists babel_2020_delete_t1;
drop table if exists babel_2020_delete_t2;
go

CREATE TABLE babel_delete_tbl1(a INT, b VARCHAR(10));
CREATE TABLE babel_delete_tbl2(a INT, b VARCHAR(10));
CREATE TABLE babel_delete_tbl3 (a INT, c INT);
INSERT INTO babel_delete_tbl1 VALUES (1, 'left'), (2, 'inner');
INSERT INTO babel_delete_tbl2 VALUES (10, 'inner'), (30, 'right');
INSERT INTO babel_delete_tbl3 VALUES (1, 10), (3, 10);
go
CREATE VIEW babel_delete_view AS SELECT * FROM babel_delete_tbl1 WHERE babel_delete_tbl1.a > 1;
go

-------------------------------------------------------------
-- DELETE with alias as target
-- BABEL-2020 already covers test cases to use alias in FROM
-------------------------------------------------------------

-- alias + plain delete
BEGIN TRAN
DELETE t1
FROM babel_delete_tbl1 AS t1
SELECT * FROM babel_delete_tbl1
ROLLBACK
GO

BEGIN TRAN
DELETE t1
FROM babel_delete_tbl1 t1
SELECT * FROM babel_delete_tbl1
ROLLBACK
GO

-- alias + subquery
BEGIN TRAN
DELETE t1
FROM babel_delete_tbl1 t1
INNER JOIN (SELECT * FROM babel_delete_tbl1) t2
ON t1.b = t2.b
SELECT * FROM babel_delete_tbl1
ROLLBACK
GO

-- alias + join
BEGIN TRAN
DELETE t1
FROM babel_delete_tbl2 t2
JOIN babel_delete_tbl1 t1
ON t2.b = t1.b
SELECT * FROM babel_delete_tbl1
ROLLBACK
go

-- alias + self join
-- BABEL-1330
BEGIN TRAN
DELETE t1
FROM babel_delete_tbl1 t1 
INNER JOIN babel_delete_tbl1 t2
ON t1.b = t2.b
SELECT * FROM babel_delete_tbl1
ROLLBACK
go

-- alias + inner join
BEGIN TRAN
DELETE t1
FROM babel_delete_tbl1 AS t1 
INNER JOIN babel_delete_tbl2 AS t2
ON t1.b = t2.b
SELECT * FROM babel_delete_tbl1
ROLLBACK
go

-- alias + non-ANSI inner join
BEGIN TRAN
DELETE t1
FROM babel_delete_tbl1 t2, babel_delete_tbl3 t1
WHERE c > 1
SELECT * FROM babel_delete_tbl3
ROLLBACK
go

-- alias + outer join
BEGIN TRAN
DELETE t1
FROM babel_delete_tbl1 AS t1 
LEFT OUTER JOIN babel_delete_tbl1 t2
ON t2.b = t1.b
SELECT * FROM babel_delete_tbl1
ROLLBACK
go

-- alias + semi join
BEGIN TRAN
DELETE t1
FROM babel_delete_tbl1 AS t1
WHERE t1.a IN
(
	SELECT a FROM babel_delete_tbl1
	WHERE babel_delete_tbl1.a = t1.a
)
SELECT * FROM babel_delete_tbl1
ROLLBACK
go

-- alias + updatable view
BEGIN TRAN
INSERT INTO babel_delete_tbl1 VALUES (3, 'extra')
DELETE v1
FROM babel_delete_view v1
WHERE a = 2
SELECT * FROM babel_delete_view
SELECT * FROM babel_delete_tbl1
ROLLBACK
go

DROP VIEW babel_delete_view
go
DROP TABLE babel_delete_tbl1
DROP TABLE babel_delete_tbl2
DROP TABLE babel_delete_tbl3
go
