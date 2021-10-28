-- Test inserting less values than columns
CREATE TABLE t1(c1 int, c2 numeric, c3 varchar(32));
GO

INSERT INTO t1 VALUES (1, 2.0, 'hello');
GO

-- Expect error
INSERT INTO t1 VALUES (1, 2.0);
GO

SELECT * FROM t1;
GO

CREATE TABLE t2(id int IDENTITY, c1 int, c2 numeric, c3 AS c1 * c2);
GO

INSERT INTO t2 VALUES (1, 2.0);
GO

-- Expect error
INSERT INTO t2 VALUES (5);
GO

SELECT * FROM t2;
GO

INSERT INTO t1 SELECT c1, c2, c3 FROM t2;
GO

SELECT * FROM t1;
GO

-- Expect error
INSERT INTO t1 SELECT id, c2 FROM t2;
GO

SELECT * FROM t1;
GO

CREATE TABLE t3(c1 int, c2 numeric);
GO

INSERT INTO t3 VALUES (2, 4);
GO

-- Expect error
INSERT INTO t1 SELECT * FROM t3;
GO

DROP TABLE t1, t2, t3;
GO
