--
-- Tests for UPDATE clause
--

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
