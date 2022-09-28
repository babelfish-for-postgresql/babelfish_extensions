---- Create table verification ----

-- Create table with Default
SELECT * FROM babel_3268_t2
GO

--Create table default function uses parameters
SELECT * FROM babel_3268_t4
GO

--CREATE table multiple defaults
SELECT * FROM babel_3268_t6
GO

---- Alter table testcases ----

--Alter table add default --
SELECT * FROM babel_3268_t1 --Verifies old rows are NOT updated with default
INSERT INTO babel_3268_t1(a,b) VALUES (2,3) --Verfies data is show instead of default if present
INSERT INTO babel_3268_t1(a) VALUES (4) --Verfies default is used if column is otherwise null
SELECT * from babel_3268_t1
GO

--Alter table full TSQL Syntax
SELECT * FROM babel_3268_t3
INSERT INTO babel_3268_t3(a,b) VALUES (2,3)
INSERT INTO babel_3268_t3(a) VALUES (4)
SELECT * from babel_3268_t3
GO

--ALTER table default function uses parameters
SELECT * FROM babel_3268_t5
INSERT INTO babel_3268_t5(a,b) VALUES (2,3)
INSERT INTO babel_3268_t5(a) VALUES (4)
SELECT * FROM babel_3268_t5
GO

--ALTER table multiple defaults will have incorrect table values because of an unrelated bug BABEL-3524
SELECT * FROM babel_3268_t7
INSERT INTO babel_3268_t7 (a) VALUES (42)
INSERT INTO babel_3268_t7 (a, c) VALUES (42, 'abc')
SELECT * FROM babel_3268_t7
GO

SELECT * FROM babel_3268_t8
INSERT INTO babel_3268_t8 (a) VALUES (42)
INSERT INTO babel_3268_t8 (a, c) VALUES (42, 'abc')
SELECT * FROM babel_3268_t8
GO