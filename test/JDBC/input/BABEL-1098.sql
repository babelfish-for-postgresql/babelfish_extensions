USE master;
GO

-- Testing delete statement
CREATE TABLE delete_test_tbl (
    age int,
    fname char(10),
    lname char(10),
    city nchar(20)
)
GO

INSERT INTO delete_test_tbl(age, fname, lname, city)
VALUES  (50, 'fname1', 'lname1', 'london'),
        (34, 'fname2', 'lname2', 'paris'),
        (50, 'fname3', 'lname3', 'brussels'),
        (90, 'fname4', 'lname4', 'new york'),
        (26, 'fname5', 'lname5', 'los angeles'),
        (74, 'fname6', 'lname6', 'tokyo'),
        (44, 'fname7', 'lname7', 'oslo'),
        (19, 'fname8', 'lname8', 'hong kong'),
        (61, 'fname9', 'lname9', 'shanghai'),
        (29, 'fname10', 'lname10', 'mumbai')
GO

CREATE TABLE delete_test_tbl2 (
    year int,
    lname char(10),
)
GO

INSERT INTO delete_test_tbl2(year, lname)
VALUES  (51, 'lname1'),
        (34, 'lname3'),
        (25, 'lname8'),
        (95, 'lname9'),
        (36, 'lname10')
GO

CREATE TABLE delete_test_tbl3 (
    lname char(10),
    city char(10),
)
GO

INSERT INTO delete_test_tbl3(lname, city)
VALUES  ('lname8','london'),
        ('lname9','tokyo'),
        ('lname10','mumbai')
GO

CREATE TABLE delete_test_tbl4 (
    age int,
    fname char(10),
    lname char(10),
    city nchar(20)
)
GO

INSERT INTO delete_test_tbl4(age, fname, lname, city)
VALUES  (50, 'fname1', 'lname1', 'london'),
        (34, 'fname2', 'lname2', 'paris'),
        (50, 'fname3', 'lname3', 'brussels'),
        (90, 'fname4', 'lname4', 'new york'),
        (26, 'fname5', 'lname5', 'los angeles'),
        (35, 'fname6', 'lname6', 'mumbai')
GO

CREATE TABLE dbo.delete_test_tbl5 (
    age int,
    fname char(10),
    lname char(10),
    city nchar(20)
)
GO

INSERT INTO dbo.delete_test_tbl5(age, fname, lname, city)
VALUES  (51, 'fname1', 'lname1', 'london'),
        (34, 'fname2', 'lname2', 'paris'),
        (102, 'fname3', 'lname10', 'brussels')
GO

-- test using schema name
DELETE dbo.delete_test_tbl5
FROM dbo.delete_test_tbl5 t5
INNER JOIN delete_test_tbl3 t3
ON t3.lname = t5.lname
GO

SELECT * FROM dbo.delete_test_tbl5 ORDER BY lname
GO

DELETE delete_test_tbl
FROM delete_test_tbl t1
INNER JOIN delete_test_tbl2 t2
ON t1.lname = t2.lname
WHERE year > 50
GO

SELECT * FROM delete_test_tbl ORDER BY lname
GO

DELETE delete_test_tbl
FROM delete_test_tbl2 t2
LEFT JOIN delete_test_tbl t1
ON t1.lname = t2.lname
WHERE t2.year < 30 AND t1.age > 40
GO

SELECT * FROM delete_test_tbl ORDER BY lname
GO

-- delete with outer join on multiple tables
DELETE delete_test_tbl
FROM delete_test_tbl3 t3
LEFT JOIN delete_test_tbl t1
ON t3.city = t1.city
LEFT JOIN delete_test_tbl2 t2
ON t1.lname = t2.lname
WHERE t3.city = 'mumbai'
GO

SELECT * FROM delete_test_tbl ORDER BY lname
GO

-- delete when target table not shown in JoinExpr
DELETE delete_test_tbl
FROM delete_test_tbl3 t3
LEFT JOIN delete_test_tbl2 t2
ON t3.lname = t2.lname
GO

SELECT * FROM delete_test_tbl ORDER BY lname
GO

-- delete with self join
DELETE delete_test_tbl3
FROM delete_test_tbl3 t1
INNER JOIN delete_test_tbl3 t2
on t1.lname = t2.lname
GO

SELECT * FROM delete_test_tbl3 ORDER BY lname
GO

DELETE delete_test_tbl4
FROM delete_test_tbl4 c
JOIN
(SELECT lname, fname, age from delete_test_tbl4) b
on b.lname = c.lname
JOIN
(SELECT lname, city, age from delete_test_tbl4) a
on a.city = c.city
GO

SELECT * FROM delete_test_tbl4 ORDER BY lname
GO

DELETE delete_test_tbl2
FROM
(SELECT lname, year from delete_test_tbl2) b
JOIN
(SELECT lname from delete_test_tbl2) a
on a.lname = b.lname
GO

SELECT * FROM delete_test_tbl2 ORDER BY lname
GO

DROP TABLE delete_test_tbl
GO

DROP TABLE delete_test_tbl2
GO

DROP TABLE delete_test_tbl3
GO

DROP TABLE delete_test_tbl4
GO

DROP TABLE dbo.delete_test_tbl5
GO


-- Tests for UPDATE clause
CREATE TABLE update_test_tbl (
    age int,
    fname char(10),
    lname char(10),
    city nchar(20)
)
GO
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
        (29, 'fname10', 'lname10', 'mumbai')
GO

CREATE TABLE update_test_tbl2 (
    year int,
    lname char(10),
)
GO

INSERT INTO update_test_tbl2(year, lname) 
VALUES  (51, 'lname1'),
        (34, 'lname3'),
        (25, 'lname8'),
        (95, 'lname9'),
        (36, 'lname10')
GO

CREATE TABLE update_test_tbl3 (
    age int,
    fname char(10),
    lname char(10),
    city nchar(20)
)
GO
INSERT INTO update_test_tbl3(lname, city)
VALUES  ('lname8','london'),
        ('lname9','tokyo'),
        ('lname10','mumbai')
GO

CREATE TABLE dbo.update_test_tbl4 (
    age int,
    fname char(10),
    lname char(10),
    city nchar(20)
)
GO

INSERT INTO dbo.update_test_tbl4(age, fname, lname, city) 
VALUES  (50, 'fname1', 'lname1', 'london'),
        (34, 'fname2', 'lname2', 'paris'),
        (35, 'fname3', 'lname3', 'brussels'),
        (90, 'fname4', 'lname10', 'new york')
GO

SELECT * FROM update_test_tbl ORDER BY lname
GO
SELECT * FROM update_test_tbl2 ORDER BY lname
GO
SELECT * FROM update_test_tbl3 ORDER BY lname
GO
SELECT * FROM dbo.update_test_tbl4 ORDER BY lname
GO
-- Simple update
UPDATE update_test_tbl SET fname = 'fname11'
GO

SELECT * FROM update_test_tbl ORDER BY lname
GO

-- Update with where clause
UPDATE update_test_tbl SET fname = 'fname12'
WHERE age > 50 AND city IN ('london','mumbai', 'new york' )
GO

SELECT * FROM update_test_tbl ORDER BY lname
GO

-- Update with inner join
UPDATE update_test_tbl SET fname = 'fname13'
FROM update_test_tbl t1
INNER JOIN update_test_tbl2 t2
ON t1.lname = t2.lname
WHERE year > 50
GO

SELECT * FROM update_test_tbl ORDER BY lname
GO

UPDATE update_test_tbl SET fname = 'fname14'
FROM update_test_tbl2 t2
INNER JOIN update_test_tbl t1
ON t1.lname = t2.lname
WHERE year < 50 AND city in ('tokyo', 'hong kong')
GO

SELECT * FROM update_test_tbl ORDER BY lname
GO

-- Update with outer join
UPDATE update_test_tbl SET fname = 'fname15'
FROM update_test_tbl2 t2
LEFT JOIN update_test_tbl t1
ON t1.lname = t2.lname
WHERE year > 50
GO

SELECT * FROM update_test_tbl ORDER BY lname
GO

UPDATE update_test_tbl SET fname = 'fname16'
FROM update_test_tbl2 t2
FULL JOIN update_test_tbl t1
ON t1.lname = t2.lname
WHERE year > 50 AND age > 60
GO

SELECT * FROM update_test_tbl ORDER BY lname
GO

-- update with outer join on multiple tables
UPDATE update_test_tbl
SET fname = 'fname17'
FROM update_test_tbl3 t3
LEFT JOIN update_test_tbl t1
ON t3.city = t1.city
LEFT JOIN update_test_tbl2 t2
ON t1.lname = t2.lname
WHERE t3.city = 'mumbai'
GO

SELECT * FROM update_test_tbl ORDER BY lname
GO

-- update when target table not shown in JoinExpr but associated by where
UPDATE update_test_tbl
SET fname = 'fname18'
from update_test_tbl2 t2
FULL JOIN update_test_tbl3 t3
ON t2.lname = t3.lname
WHERE update_test_tbl.city = t3.city AND t3.lname='lname10'
GO

SELECT * FROM update_test_tbl ORDER BY lname
GO

-- update when target table not shown in JoinExpr
UPDATE update_test_tbl
SET fname = 'fname19'
from update_test_tbl2 t2
FULL JOIN update_test_tbl3 t3
ON t2.lname = t3.lname
GO

SELECT * FROM update_test_tbl ORDER BY lname
GO

-- update with self join
UPDATE update_test_tbl3
SET lname = 'lname12'
FROM update_test_tbl3 t1
INNER JOIN update_test_tbl3 t2
on t1.lname = t2.lname
GO

SELECT * FROM update_test_tbl3 ORDER BY lname
GO

UPDATE update_test_tbl SET lname='lname13'
FROM update_test_tbl c
JOIN
(SELECT lname, fname, age from update_test_tbl) b
on b.lname = c.lname
JOIN
(SELECT lname, city, age from update_test_tbl) a
on a.city = c.city
GO

SELECT * FROM update_test_tbl ORDER BY lname
GO

-- update when target table only appears in subselect
UPDATE update_test_tbl SET lname='lname14'
FROM
(SELECT lname, fname, age from update_test_tbl) b
JOIN
(SELECT lname, city, age from update_test_tbl) a
on a.lname = b.lname;

SELECT * FROM update_test_tbl ORDER BY lname
GO

-- update with schema
UPDATE dbo.update_test_tbl4 SET fname = 'fname11'
FROM dbo.update_test_tbl4 t4 
INNER JOIN update_test_tbl3 t3
ON t3.city = t4.city
GO

SELECT * FROM dbo.update_test_tbl4 ORDER BY lname
GO

DROP TABLE update_test_tbl
GO
DROP TABLE update_test_tbl2
GO
DROP TABLE update_test_tbl3
GO
DROP TABLE dbo.update_test_tbl4
GO
