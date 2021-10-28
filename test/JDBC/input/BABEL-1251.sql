CREATE SCHEMA babel_1251;
GO

-- Test id as second column
CREATE TABLE babel_1251.t1(col1 INT, id INT IDENTITY(1, 1) NOT NULL);
go
SET IDENTITY_INSERT babel_1251.t1 ON;
go
INSERT INTO babel_1251.t1(col1, id) VALUES (1, 10);
go
SELECT @@IDENTITY;
go
SET IDENTITY_INSERT babel_1251.t1 OFF;
go
INSERT INTO babel_1251.t1(col1) VALUES (1);
go
SELECT * FROM babel_1251.t1;
go
SELECT @@IDENTITY;
go

-- Test id as middle column
CREATE TABLE babel_1251.t2(col1 VARCHAR(32), id INT IDENTITY(1, -1), col2 INT);
go
SET IDENTITY_INSERT babel_1251.t2 ON;
go
INSERT INTO babel_1251.t2(col1, id, col2) VALUES ('hello', -10, 1);
go
SELECT @@IDENTITY;
go
SET IDENTITY_INSERT babel_1251.t2 OFF;
go
INSERT INTO babel_1251.t2(col1, col2) VALUES ('world', 1);
go
SELECT @@IDENTITY;
go
SELECT * FROM babel_1251.t2;
go

-- Test id as last column
CREATE TABLE babel_1251.t3(col1 VARCHAR(32), col2 INT, id INT IDENTITY);
go
INSERT INTO babel_1251.t3(col1, col2) VALUES ('hello', 1);
go
SELECT @@IDENTITY;
go
SET IDENTITY_INSERT babel_1251.t3 ON;
go
INSERT INTO babel_1251.t3(col1, col2, id) VALUES ('hello', 1, 20);
go
SET IDENTITY_INSERT babel_1251.t3 OFF;
go
SELECT @@IDENTITY;
go
INSERT INTO babel_1251.t3(col1, col2) VALUES ('hello', 1);
go
SELECT @@IDENTITY;
go
SET IDENTITY_INSERT babel_1251.t3 ON;
go
INSERT INTO babel_1251.t3(col1, col2, id) VALUES ('hello', 1, 30);
go
SELECT @@IDENTITY;
go
SET IDENTITY_INSERT babel_1251.t3 OFF;
go
SELECT * FROM babel_1251.t3;
go
SELECT @@IDENTITY;
go

DROP TABLE babel_1251.t1, babel_1251.t2, babel_1251.t3;
go

DROP SCHEMA babel_1251;
GO
