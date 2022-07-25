CREATE SCHEMA babel_1251;
GO

-- Test id as second column
CREATE TABLE babel_1251.t1(col1 INT, id INT IDENTITY(1, 1) NOT NULL);
go

CREATE TABLE babel_1251.t2(col1 VARCHAR(32), id INT IDENTITY(1, -1), col2 INT);
go

CREATE TABLE babel_1251.t3(col1 VARCHAR(32), col2 INT, id INT IDENTITY);
go