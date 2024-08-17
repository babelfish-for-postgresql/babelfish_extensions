USE MASTER;
GO

CREATE DATABASE db1;
GO

USE db1;
GO

CREATE TABLE t1 (id INT, c1 INT);
GO

INSERT INTO t1 (id, c1) VALUES (1, 2);
GO

USE MASTER;
GO

-- Cannot find db1 table t1
INSERT INTO t1 (id, c1) VALUES (2, 4);
GO

BEGIN TRAN;
GO

USE db1;
GO

INSERT INTO t1 (id, c1) VALUES (3, 8);
GO

ROLLBACK;
GO

SELECT current_user;
GO

SELECT current_schema();
GO

INSERT INTO t1 (id, c1) VALUES (4, 16);
GO

SELECT * FROM t1;
GO

USE MASTER;
GO

DROP DATABASE db1;
GO

-- Tests for db level collation
CREATE DATABASE db1 COLLATE BBF_Unicode_CP1_CI_AI;
GO

USE db1;
GO

CREATE TABLE t1 (id INT, c1 INT);
GO

INSERT INTO t1 (id, c1) VALUES (1, 2);
GO

USE MASTER;
GO

-- Cannot find db1 table t1
INSERT INTO t1 (id, c1) VALUES (2, 4);
GO

BEGIN TRAN;
GO

USE db1;
GO

INSERT INTO t1 (id, c1) VALUES (3, 8);
GO

ROLLBACK;
GO

SELECT current_user;
GO

SELECT current_schema();
GO

INSERT INTO t1 (id, c1) VALUES (4, 16);
GO

SELECT * FROM t1;
GO

USE MASTER;
GO

DROP DATABASE db1;
GO
