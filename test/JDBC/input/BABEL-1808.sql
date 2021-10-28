-- Test DDL
CREATE TABLE t1 ( a [Decimal], b [DeCimal](18,0));
GO

-- Test Default value
CREATE TABLE t2 ( a Decimal, b [DeCimal]);
GO

INSERT INTO t2 values (3.14, 3.14);
SELECT * FROM t2;
GO

-- Test Identity column

CREATE TABLE t3 ( a Decimal IDENTITY, b INT);
GO

INSERT INTO t3 (b) VALUES (10);
SELECT * FROM t3;
GO

CREATE TABLE t4 ( a [Decimal] IDENTITY, b INT);
GO

INSERT INTO t4 (b) VALUES (10);
SELECT * FROM t4;
GO

-- test error
CREATE TABLE t5 ( a Decimal(18,2) IDENTITY, b int);
GO

DROP TABLE t1;
GO
DROP TABLE t2;
GO
DROP TABLE t3;
GO
DROP TABLE t4;
GO
