create table t (a int, b int)
go

insert t values(1,1)
insert t values(2,2)
insert t values(3,3)
insert t values(4,4)
insert t values(5,5)
go

select * from t
go

update t set b = b*-1 where b > 0
go

select * from t
go

update top(2) t set b = b*-1 where b < 0
go

select count(*) from t where b > 0
go

delete top(2) from t where b < 0
go

select count(*) from t
go

declare @a int
set @a = 1
delete top (@a) from t
go

select count(*) from t
go

-- test TOP clause in UPDATE together with JOIN
create table t1 (a int, b int)
go

insert t1 values(1,1)
insert t1 values(2,2)
insert t1 values(3,3)
insert t1 values(4,4)
insert t1 values(5,5)
go

create table t2 (a int, b int)
go

insert t2 values(1,-1)
insert t2 values(2,2)
insert t2 values(3,3)
insert t2 values(400,4)
insert t2 values(500,5)
go

update top(2) t1 set t1.a = t1.a*-1 from t1 inner join t2 alias2 on t1.a = alias2.a
go

select count(*) from t1 where a < 0
go

-- test TOP clause in DELETE together with JOIN
create table t3 (a int, b int)
go

insert t3 values(1,1)
insert t3 values(2,2)
insert t3 values(-3,-3)
go

create table t4 (a int, b int)
go

insert t4 values(1,-1)
insert t4 values(2,2)
insert t4 values(3,3)
insert t4 values(400,4)
insert t4 values(500,5)
go

delete top(1) t3 from t3 alias3 inner join t4 alias4 on alias3.b = alias4.b
go

select count(*) from t3
go

-- test error message on TOP n PERCENT
-- TOP 100 PERCENT should be supported
update top (100) percent t3 set b = 100
go

select count(*) from t3 where b = 100
go

delete top (100) percent from t3
go

select count(*) from t3
go

-- other percentage should report unsupported error
update top (10) percent t4 set b = 100
go

delete top (10) percent from t4
go

drop table t
go

drop table t1
go

drop table t2
go

drop table t3
go

drop table t4
go

-------------------------------------------------------------
-- Tests for UPDATE
-------------------------------------------------------------

CREATE TABLE update_test_tbl (
    age int,
    fname char(10),
    lname char(10),
    city nchar(20)
);
go

INSERT INTO update_test_tbl(age, fname, lname, city) 
VALUES  (50, 'fname1', 'lname1', 'london'),
        (34, 'fname2', 'lname2', 'paris'),
        (35, 'fname3', 'lname3', 'brussels'),
        (90, 'fname4', 'lname4', 'new york'),
        (26, 'fname5', 'lname5', 'los angeles'),
        (74, 'fname6', 'lname6', 'tokyo'),
        (44, 'fname7', 'lname7', 'oslo'),
        (19, 'fname8', 'lname8', 'hong kong'),
        (61, 'fname9', 'lname9', 'shanghai'),
        (29, 'fname10', 'lname10', 'mumbai');

CREATE TABLE update_test_tbl2 (
    year int,
    lname char(10),
);
go

INSERT INTO update_test_tbl2(year, lname) 
VALUES  (51, 'lname1'),
        (34, 'lname3'),
        (25, 'lname8'),
        (95, 'lname9'),
        (36, 'lname10');
go

CREATE TABLE update_test_tbl3 (
    lname char(10),
    city char(10),
);
go

INSERT INTO update_test_tbl3(lname, city)
VALUES  ('lname8','london'),
        ('lname9','tokyo'),
        ('lname10','mumbai');
go

-- Simple update
UPDATE top(2) update_test_tbl SET fname = 'fname11';
go

-- Update with where clause
UPDATE top(1) update_test_tbl SET fname = 'fname12'
WHERE age > 30 AND city IN ('london','mumbai', 'new york' );
go

-- Update with inner join
UPDATE top(1) update_test_tbl SET fname = 'fname13'
FROM update_test_tbl t1
INNER JOIN update_test_tbl2 t2
ON t1.lname = t2.lname
WHERE year > 50;
go

UPDATE top(1) update_test_tbl SET fname = 'fname14'
FROM update_test_tbl2 t2
INNER JOIN update_test_tbl t1
ON t1.lname = t2.lname
WHERE year < 100 AND city in ('tokyo', 'hong kong');
go

-- Update with outer join
UPDATE top(1) update_test_tbl SET fname = 'fname15'
FROM update_test_tbl2 t2
LEFT JOIN update_test_tbl t1
ON t1.lname = t2.lname
WHERE year > 50;
go

UPDATE top(1) update_test_tbl SET fname = 'fname16'
FROM update_test_tbl2 t2
FULL JOIN update_test_tbl t1
ON t1.lname = t2.lname
WHERE year > 50 AND age > 0;
go

-- update with outer join on multiple tables
UPDATE top(1) update_test_tbl
SET fname = 'fname17'
FROM update_test_tbl3 t3
LEFT JOIN update_test_tbl t1
ON t3.city = t1.city
LEFT JOIN update_test_tbl2 t2
ON t1.lname = t2.lname
WHERE t3.city in ('mumbai', 'tokyo');
go

-- update when target table not shown in JoinExpr
UPDATE top(5) update_test_tbl
SET fname = 'fname19'
from update_test_tbl2 t2
FULL JOIN update_test_tbl3 t3
ON t2.lname = t3.lname;
go

-- update with self join
UPDATE top(7) update_test_tbl SET lname='lname13'
FROM update_test_tbl c
JOIN
(SELECT lname, fname, age from update_test_tbl) b
on b.lname = c.lname
JOIN
(SELECT lname, city, age from update_test_tbl) a
on a.city = c.city;
go

-- update when target table only appears in subselect
UPDATE top(2) update_test_tbl SET lname='lname14'
FROM
(SELECT lname, fname, age from update_test_tbl) b
JOIN
(SELECT lname, city, age from update_test_tbl) a
on a.lname = b.lname;
go

DROP TABLE update_test_tbl;
go
DROP TABLE update_test_tbl2;
go
DROP TABLE update_test_tbl3;
go

-------------------------------------------------------------
-- BABEL-2020
-------------------------------------------------------------
drop procedure if exists babel_2020_update_ct;
go

create procedure babel_2020_update_ct as
begin
    drop table if exists babel_2020_update_t1
    create table babel_2020_update_t1 (a int)
    insert into babel_2020_update_t1 values (1), (2), (NULL)
    drop table if exists babel_2020_update_t2
    create table babel_2020_update_t2 (a int)
    insert into babel_2020_update_t2 values (2), (3), (NULL)
end
go

-- single tables in FROM clause
exec babel_2020_update_ct;
update top(1) babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x;
go

-- JOIN clause
exec babel_2020_update_ct;
update top(1) babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x join babel_2020_update_t2 y on 1 = 1;
go

exec babel_2020_update_ct;
update top(1) babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x join babel_2020_update_t2 y on y.a = 2;
go

-- subqueries
exec babel_2020_update_ct;
update top(1) babel_2020_update_t1 set a = 100 from (select * from babel_2020_update_t1) x;
go

-- self join
exec babel_2020_update_ct;
update top(1) babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x, (select * from babel_2020_update_t1) y;
go

-- outer joins
exec babel_2020_update_ct;
update top(1) babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x left outer join babel_2020_update_t2 on babel_2020_update_t2.a = x.a;
go

-- semi joins
exec babel_2020_update_ct;
update top(1) babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x where x.a in (select a from babel_2020_update_t1 where babel_2020_update_t1.a = x.a);
go

exec babel_2020_update_ct;
update top(1) babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x where not exists (select a from babel_2020_update_t1 y where y.a + 1 = x.a);
go

drop procedure if exists babel_2020_update_ct;
drop table if exists babel_2020_update_t1;
drop table if exists babel_2020_update_t2;
go

CREATE TABLE babel_update_tbl1(a INT, b VARCHAR(10));
CREATE TABLE babel_update_tbl2(a INT, b VARCHAR(10));
CREATE TABLE babel_update_tbl3 (a INT, c INT);
INSERT INTO babel_update_tbl1 VALUES (1, 'left'), (2, 'inner');
INSERT INTO babel_update_tbl2 VALUES (10, 'inner'), (30, 'right');
INSERT INTO babel_update_tbl3 VALUES (1, 10), (3, 10);
go
CREATE VIEW babel_update_view AS SELECT * FROM babel_update_tbl1 WHERE babel_update_tbl1.a > 1;
go
CREATE SCHEMA babel_update_schema
go
CREATE TABLE babel_update_schema.babel_update_tbl1(a INT);
INSERT INTO babel_update_schema.babel_update_tbl1 VALUES (1), (2);
go

-------------------------------------------------------------
-- UPDATE with alias as target
-- BABEL-2020 already covers test cases to use alias in FROM
-------------------------------------------------------------
-- alias + plain update
-- BABEL-2675
BEGIN TRAN
UPDATE top(1) t1 SET a = a + 1
FROM babel_update_tbl1 AS t1
ROLLBACK
GO

-- BABEL-3775
BEGIN TRAN
UPDATE top(1) t1 SET t1.a = a + 1
FROM babel_update_tbl1 t1
ROLLBACK
GO

-- alias + subquery
-- BABEL-1875
BEGIN TRAN
UPDATE top(1) t1 SET a = t1.a + 1
FROM babel_update_tbl1 t1
INNER JOIN (SELECT * FROM babel_update_tbl1) t2
ON t1.b = t2.b
ROLLBACK
GO

-- alias + join
BEGIN TRAN
UPDATE top(1) t1 SET a = 10
FROM babel_update_tbl2 t2
JOIN babel_update_tbl1 t1
ON t2.b = t1.b
ROLLBACK
go

-- alias + self join
-- BABEL-1330
BEGIN TRAN
UPDATE top(1) t1 SET t1.a = t1.a + 1
FROM babel_update_tbl1 t1 
INNER JOIN babel_update_tbl1 t2
ON t1.b = t2.b
ROLLBACK
go

-- alias + inner join
-- BABEL-3091
BEGIN TRAN
UPDATE top(1) t1 SET t1.a = t2.a
FROM babel_update_tbl1 AS t1 
INNER JOIN babel_update_tbl2 AS t2
ON t1.b = t2.b
ROLLBACK
go

-- alias + non-ANSI inner join
-- BABEL-3685
BEGIN TRAN
UPDATE top(1) t1 SET a = 10
FROM babel_update_tbl1 t2, babel_update_tbl3 t1
WHERE c > 1
ROLLBACK
go

-- alias + outer join
BEGIN TRAN
UPDATE top(1) t1 SET a = 100
FROM babel_update_tbl1 AS t1 
LEFT OUTER JOIN babel_update_tbl1 t2
ON t2.b = t1.b
ROLLBACK
go

-- alias + semi join
BEGIN TRAN
UPDATE top(1) t1 SET a = 100
FROM babel_update_tbl1 AS t1
WHERE t1.a IN
(
	SELECT a FROM babel_update_tbl1
	WHERE babel_update_tbl1.a = t1.a
)
ROLLBACK
go

-- alias + updatable view
BEGIN TRAN
INSERT INTO babel_update_tbl1 VALUES (3, 'extra')
UPDATE top(1) v1 SET a = 100
FROM babel_update_view v1
WHERE a = 2
ROLLBACK
go

-- alias + table ref with schema
BEGIN TRAN
UPDATE top(1) t1 SET t1.a = a + 1
FROM babel_update_schema.babel_update_tbl1 t1
ROLLBACK
GO

DROP VIEW babel_update_view
go
DROP TABLE babel_update_tbl1
DROP TABLE babel_update_tbl2
DROP TABLE babel_update_tbl3
DROP TABLE babel_update_schema.babel_update_tbl1
go
DROP SCHEMA babel_update_schema
go

-------------------------------------------------------------
-- BABEL-2020: DELETE
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
delete top(2) babel_2020_delete_t1 from babel_2020_delete_t1 x;
go

-- JOIN clause
exec babel_2020_delete_ct;
delete top(1) babel_2020_delete_t1 from babel_2020_delete_t1 x join babel_2020_delete_t2 y on 1 = 1;
go

exec babel_2020_delete_ct;
delete top(2) babel_2020_delete_t1 from babel_2020_delete_t1 x join babel_2020_delete_t2 y on y.a = 2;
go

-- subqueries
exec babel_2020_delete_ct;
delete top(1) babel_2020_delete_t1 from (select * from babel_2020_delete_t1) x;
go

-- self join
exec babel_2020_delete_ct;
delete top(1) babel_2020_delete_t1 from babel_2020_delete_t1 x, (select * from babel_2020_delete_t1) y where x.a + 1 >= y.a;
go

-- outer joins
exec babel_2020_delete_ct;
delete top(1) babel_2020_delete_t1 from babel_2020_delete_t1 x left outer join babel_2020_delete_t2 on babel_2020_delete_t2.a = x.a;
go

-- semi joins
exec babel_2020_delete_ct;
delete top(1) babel_2020_delete_t1 from babel_2020_delete_t1 x where x.a in (select a from babel_2020_delete_t1 where babel_2020_delete_t1.a = x.a);
go

exec babel_2020_delete_ct;
delete top(1) babel_2020_delete_t1 from babel_2020_delete_t1 x where not exists (select a from babel_2020_delete_t1 y where y.a + 1 = x.a);
go

drop procedure if exists babel_2020_delete_ct;
drop table if exists babel_2020_delete_t1;
drop table if exists babel_2020_delete_t2;
go

-- DELETE with alias as target
CREATE TABLE babel_delete_tbl1(a INT, b VARCHAR(10));
CREATE TABLE babel_delete_tbl2(a INT, b VARCHAR(10));
CREATE TABLE babel_delete_tbl3 (a INT, c INT);
INSERT INTO babel_delete_tbl1 VALUES (1, 'left'), (2, 'inner');
INSERT INTO babel_delete_tbl2 VALUES (10, 'inner'), (30, 'right');
INSERT INTO babel_delete_tbl3 VALUES (1, 10), (3, 10);
go

CREATE VIEW babel_delete_view AS SELECT * FROM babel_delete_tbl1 WHERE babel_delete_tbl1.a > 1;
go
CREATE SCHEMA babel_delete_schema
go
CREATE TABLE babel_delete_schema.babel_delete_tbl1(a INT);
INSERT INTO babel_delete_schema.babel_delete_tbl1 VALUES (1), (2);
go

-- alias + plain delete
BEGIN TRAN
DELETE top(1) t1
FROM babel_delete_tbl1 AS t1
ROLLBACK
GO

BEGIN TRAN
DELETE top(1) t1
FROM babel_delete_tbl1 t1
ROLLBACK
GO

-- alias + subquery
BEGIN TRAN
DELETE top(1) t1
FROM babel_delete_tbl1 t1
INNER JOIN (SELECT * FROM babel_delete_tbl1) t2
ON t1.b = t2.b
ROLLBACK
GO

-- alias + join
BEGIN TRAN
DELETE top(1) t1
FROM babel_delete_tbl2 t2
JOIN babel_delete_tbl1 t1
ON t2.b = t1.b
ROLLBACK
go

-- alias + self join
-- BABEL-1330
BEGIN TRAN
DELETE top(1) t1
FROM babel_delete_tbl1 t1 
INNER JOIN babel_delete_tbl1 t2
ON t1.b = t2.b
ROLLBACK
go

-- alias + inner join
BEGIN TRAN
DELETE top(1) t1
FROM babel_delete_tbl1 AS t1 
INNER JOIN babel_delete_tbl2 AS t2
ON t1.b = t2.b
ROLLBACK
go

-- alias + non-ANSI inner join
BEGIN TRAN
DELETE top(1) t1
FROM babel_delete_tbl1 t2, babel_delete_tbl3 t1
WHERE c > 1
ROLLBACK
go

-- alias + outer join
BEGIN TRAN
DELETE top(1) t1
FROM babel_delete_tbl1 AS t1 
LEFT OUTER JOIN babel_delete_tbl1 t2
ON t2.b = t1.b
ROLLBACK
go

-- alias + semi join
BEGIN TRAN
DELETE top(1) t1
FROM babel_delete_tbl1 AS t1
WHERE t1.a IN
(
	SELECT a FROM babel_delete_tbl1
	WHERE babel_delete_tbl1.a = t1.a
)
ROLLBACK
go

-- alias + updatable view
BEGIN TRAN
INSERT INTO babel_delete_tbl1 VALUES (3, 'extra')
DELETE top(1) v1
FROM babel_delete_view v1
WHERE a = 2
ROLLBACK
go

-- alias + table ref with schema
BEGIN TRAN
DELETE top(1) t1
FROM babel_delete_schema.babel_delete_tbl1 t1
ROLLBACK
GO

-- target with schema
BEGIN TRAN
DELETE top(1) babel_delete_schema.babel_delete_tbl1
ROLLBACK
GO

-- should fail, same exposed names
DELETE top(1) babel_delete_schema.babel_delete_tbl1
FROM babel_delete_tbl1
GO

-- should fail, same exposed names
DELETE top(1) babel_delete_schema.babel_delete_tbl1
FROM babel_delete_tbl2 AS babel_delete_tbl1
GO


DROP VIEW babel_delete_view
go
DROP TABLE babel_delete_tbl1
DROP TABLE babel_delete_tbl2
DROP TABLE babel_delete_tbl3
DROP TABLE babel_delete_schema.babel_delete_tbl1
go
DROP SCHEMA babel_delete_schema
go
