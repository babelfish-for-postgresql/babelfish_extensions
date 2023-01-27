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

SELECT * FROM update_test_tbl ORDER BY lname;
go
SELECT * FROM update_test_tbl2 ORDER BY lname;
go
SELECT * FROM update_test_tbl3 ORDER BY lname;
go
-- Simple update
UPDATE update_test_tbl SET fname = 'fname11';
go

SELECT * FROM update_test_tbl ORDER BY lname;
go

-- Update with where clause
UPDATE update_test_tbl SET fname = 'fname12'
WHERE age > 50 AND city IN ('london','mumbai', 'new york' );
go

SELECT * FROM update_test_tbl ORDER BY lname;
go

-- Update with inner join
UPDATE update_test_tbl SET fname = 'fname13'
FROM update_test_tbl t1
INNER JOIN update_test_tbl2 t2
ON t1.lname = t2.lname
WHERE year > 50;
go

SELECT * FROM update_test_tbl ORDER BY lname;
go

UPDATE update_test_tbl SET fname = 'fname14'
FROM update_test_tbl2 t2
INNER JOIN update_test_tbl t1
ON t1.lname = t2.lname
WHERE year < 50 AND city in ('tokyo', 'hong kong');
go

SELECT * FROM update_test_tbl ORDER BY lname;
go

-- Update with outer join
UPDATE update_test_tbl SET fname = 'fname15'
FROM update_test_tbl2 t2
LEFT JOIN update_test_tbl t1
ON t1.lname = t2.lname
WHERE year > 50;
go

SELECT * FROM update_test_tbl ORDER BY lname;
go

UPDATE update_test_tbl SET fname = 'fname16'
FROM update_test_tbl2 t2
FULL JOIN update_test_tbl t1
ON t1.lname = t2.lname
WHERE year > 50 AND age > 60;
go

SELECT * FROM update_test_tbl ORDER BY lname;
go

-- update with outer join on multiple tables
UPDATE update_test_tbl
SET fname = 'fname17'
FROM update_test_tbl3 t3
LEFT JOIN update_test_tbl t1
ON t3.city = t1.city
LEFT JOIN update_test_tbl2 t2
ON t1.lname = t2.lname
WHERE t3.city = 'mumbai';
go

SELECT * FROM update_test_tbl ORDER BY lname;
go

-- update when target table not shown in JoinExpr
UPDATE update_test_tbl
SET fname = 'fname19'
from update_test_tbl2 t2
FULL JOIN update_test_tbl3 t3
ON t2.lname = t3.lname;
go

SELECT * FROM update_test_tbl ORDER BY lname;
go

-- update with self join
UPDATE update_test_tbl3
SET lname = 'lname12'
FROM update_test_tbl3 t1
INNER JOIN update_test_tbl3 t2
on t1.lname = t2.lname;
go

SELECT * FROM update_test_tbl3 ORDER BY lname;
go

UPDATE update_test_tbl SET lname='lname13'
FROM update_test_tbl c
JOIN
(SELECT lname, fname, age from update_test_tbl) b
on b.lname = c.lname
JOIN
(SELECT lname, city, age from update_test_tbl) a
on a.city = c.city;
go

SELECT * FROM update_test_tbl ORDER BY lname;
go

-- update when target table only appears in subselect
UPDATE update_test_tbl SET lname='lname14'
FROM
(SELECT lname, fname, age from update_test_tbl) b
JOIN
(SELECT lname, city, age from update_test_tbl) a
on a.lname = b.lname;
go

SELECT * FROM update_test_tbl ORDER BY lname;
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
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x where x.a = 2;
go
 
-- multiple tables in FROM clause
exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x, babel_2020_update_t2 y;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x, babel_2020_update_t2 y where x.a = 2;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x, babel_2020_update_t2 y where y.a = 2;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x, babel_2020_update_t2 y where x.a = y.a;
go

-- JOIN clause
exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x join babel_2020_update_t2 y on 1 = 1;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x join babel_2020_update_t2 y on x.a = 2;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x join babel_2020_update_t2 y on y.a = 2;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x join babel_2020_update_t2 y on x.a = y.a;
go

-- subqueries
exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from (select * from babel_2020_update_t1) x;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x, (select * from babel_2020_update_t1) y;
go

-- self join
exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x, (select * from babel_2020_update_t1) y where x.a + 1 = y.a;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 y, (select * from babel_2020_update_t1) x where x.a + 1 = y.a;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x join babel_2020_update_t1 on babel_2020_update_t1.a + 1 = x.a;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 join babel_2020_update_t1 x on babel_2020_update_t1.a + 1 = x.a;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x, babel_2020_update_t1 y where x.a + 1 = y.a;
go

-- outer joins
exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x left outer join babel_2020_update_t2 on babel_2020_update_t2.a = x.a;
go

-- will be tracked in BABEL-3910
--exec babel_2020_update_ct;
--update babel_2020_update_t1 set a = 100 from babel_2020_update_t2 left outer join babel_2020_update_t1 x on babel_2020_update_t2.a = x.a;
--go

-- null filters
exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x where x.a is null;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t2 left outer join babel_2020_update_t1 x on x.a is null;
go

-- updatable views
drop view if exists babel_2020_update_v1;
go

exec babel_2020_update_ct;
go

create view babel_2020_update_v1 as select * from babel_2020_update_t1 where babel_2020_update_t1.a is not null;
go

update babel_2020_update_v1 set a = 100 from babel_2020_update_v1 x where x.a = 2;
go

drop view if exists babel_2020_update_v1;
go
 
-- semi joins
exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x where x.a in (select a from babel_2020_update_t1 where babel_2020_update_t1.a = x.a);
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x where not exists (select a from babel_2020_update_t1 y where y.a + 1 = x.a);
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x where exists (select a from babel_2020_update_t1 y where y.a + 1 = x.a);
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
UPDATE t1 SET a = a + 1
FROM babel_update_tbl1 AS t1
SELECT * FROM babel_update_tbl1
ROLLBACK
GO

-- BABEL-3775
BEGIN TRAN
UPDATE t1 SET t1.a = a + 1
FROM babel_update_tbl1 t1
SELECT * FROM babel_update_tbl1
ROLLBACK
GO

-- alias + subquery
-- BABEL-1875
BEGIN TRAN
UPDATE t1 SET a = t1.a + 1
FROM babel_update_tbl1 t1
INNER JOIN (SELECT * FROM babel_update_tbl1) t2
ON t1.b = t2.b
SELECT * FROM babel_update_tbl1
ROLLBACK
GO

-- alias + join
BEGIN TRAN
UPDATE t1 SET a = 10
FROM babel_update_tbl2 t2
JOIN babel_update_tbl1 t1
ON t2.b = t1.b
SELECT * FROM babel_update_tbl1
ROLLBACK
go

-- alias + self join
-- BABEL-1330
BEGIN TRAN
UPDATE t1 SET t1.a = t1.a + 1
FROM babel_update_tbl1 t1 
INNER JOIN babel_update_tbl1 t2
ON t1.b = t2.b
SELECT * FROM babel_update_tbl1
ROLLBACK
go

-- alias + inner join
-- BABEL-3091
BEGIN TRAN
UPDATE t1 SET t1.a = t2.a
FROM babel_update_tbl1 AS t1 
INNER JOIN babel_update_tbl2 AS t2
ON t1.b = t2.b
SELECT * FROM babel_update_tbl1
ROLLBACK
go

-- alias + non-ANSI inner join
-- BABEL-3685
BEGIN TRAN
UPDATE t1 SET a = 10
FROM babel_update_tbl1 t2, babel_update_tbl3 t1
WHERE c > 1
SELECT * FROM babel_update_tbl3
ROLLBACK
go

-- alias + outer join
BEGIN TRAN
UPDATE t1 SET a = 100
FROM babel_update_tbl1 AS t1 
LEFT OUTER JOIN babel_update_tbl1 t2
ON t2.b = t1.b
SELECT * FROM babel_update_tbl1
ROLLBACK
go

-- alias + semi join
BEGIN TRAN
UPDATE t1 SET a = 100
FROM babel_update_tbl1 AS t1
WHERE t1.a IN
(
	SELECT a FROM babel_update_tbl1
	WHERE babel_update_tbl1.a = t1.a
)
SELECT * FROM babel_update_tbl1
ROLLBACK
go

-- alias + updatable view
BEGIN TRAN
INSERT INTO babel_update_tbl1 VALUES (3, 'extra')
UPDATE v1 SET a = 100
FROM babel_update_view v1
WHERE a = 2
SELECT * FROM babel_update_view
SELECT * FROM babel_update_tbl1
ROLLBACK
go

-- alias + table ref with schema
BEGIN TRAN
UPDATE t1 SET t1.a = a + 1
FROM babel_update_schema.babel_update_tbl1 t1
SELECT * fROM babel_update_schema.babel_update_tbl1
ROLLBACK
GO

-------------------------------------------------------------
-- Other test cases
-------------------------------------------------------------
BEGIN TRAN
UPDATE babel_update_tbl1 SET a = 2 
FROM babel_update_tbl1
SELECT * FROM babel_update_tbl1
ROLLBACK
go

BEGIN TRAN
UPDATE babel_update_tbl1 SET a = t1.a + 1
FROM babel_update_tbl1 t1
SELECT * FROM babel_update_tbl1
ROLLBACK
go

BEGIN TRAN
UPDATE babel_update_tbl1 SET a = 100
FROM babel_update_tbl1, babel_update_tbl2 t2
SELECT * FROM babel_update_tbl1
ROLLBACK
go

-- table ref with schema
BEGIN TRAN
UPDATE babel_update_tbl1 SET a = 100
FROM babel_update_schema.babel_update_tbl1
SELECT * FROM babel_update_schema.babel_update_tbl1
ROLLBACK
GO

-- target with schema
BEGIN TRAN
UPDATE babel_update_schema.babel_update_tbl1 SET a = a + 1
SELECT * fROM babel_update_schema.babel_update_tbl1
ROLLBACK
GO

-- should fail, same exposed names
UPDATE babel_update_schema.babel_update_tbl1 SET a = 0
FROM babel_update_tbl1
GO

-- should fail, same exposed names
UPDATE babel_update_schema.babel_update_tbl1 SET a = 0
FROM babel_update_tbl2 AS babel_update_tbl1
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
