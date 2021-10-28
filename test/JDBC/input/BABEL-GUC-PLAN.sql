CREATE TABLE test_table1(test_id INT IDENTITY, test_col1 INT);
go

CREATE TABLE test_table2(test_id INT IDENTITY, test_col1 INT);
go

CREATE PROCEDURE insert_test_table1_stmt1
AS BEGIN
INSERT INTO test_table1 (test_id, test_col1) VALUES (5, 1);
END;
go

CREATE PROCEDURE insert_test_table1_stmt1_outer
AS BEGIN
EXEC insert_test_table1_stmt1;
END;
go

CREATE PROCEDURE insert_test_table1_stmt2
AS BEGIN
INSERT INTO test_table1 (test_id, test_col1) VALUES (8, 2);
END;
go

CREATE PROCEDURE insert_test_table1_stmt2_outer
AS BEGIN
EXEC insert_test_table1_stmt2;
END;
go

CREATE PROCEDURE insert_test_table1_stmt3
AS BEGIN
INSERT INTO test_table1 (test_id, test_col1) VALUES (10, 3);
END;
go

CREATE PROCEDURE insert_test_table1_stmt4
AS BEGIN
INSERT INTO test_table1 (test_id, test_col1) VALUES (64, 4);
END;
go

CREATE PROCEDURE insert_test_table1_stmt5
AS BEGIN
INSERT INTO test_table1 (test_id, test_col1) VALUES (128, 5);
END;
go

CREATE PROCEDURE insert_test_table1_stmt6
AS BEGIN
INSERT INTO test_table1 (test_id, test_col1) VALUES (-2, 6);
END;
go

CREATE PROCEDURE insert_test_table1_test_multi_stmts
AS BEGIN
EXEC insert_test_table1_stmt1
EXEC insert_test_table1_stmt2
EXEC insert_test_table1_stmt3
EXEC insert_test_table1_stmt4
EXEC insert_test_table1_stmt5
EXEC insert_test_table1_stmt6

EXEC insert_test_table1_stmt3
EXEC insert_test_table1_stmt5
EXEC insert_test_table1_stmt4
EXEC insert_test_table1_stmt6
EXEC insert_test_table1_stmt1
EXEC insert_test_table1_stmt2
END;
go

CREATE PROCEDURE insert_test_table1_val
@val INT
AS BEGIN
INSERT INTO test_table1 VALUES (@val);
END;
go

-- Test re-planning based on GUC state
SET IDENTITY_INSERT test_table1 ON;
go

EXEC insert_test_table1_stmt1_outer;
go

EXEC insert_test_table1_stmt2_outer;
go

SET IDENTITY_INSERT test_table1 OFF;
go

EXEC insert_test_table1_stmt1_outer;
go

EXEC insert_test_table1_stmt2_outer;
go

SET IDENTITY_INSERT test_table1 ON;

EXEC insert_test_table1_test_multi_stmts;
go

SET IDENTITY_INSERT test_table1 OFF;
go

-- Test a follow-up regular INSERT
EXEC insert_test_table1_val 7;
go

SELECT * FROM test_table1;
go

-- Test procedure drops
SET IDENTITY_INSERT test_table1 ON;
go

EXEC insert_test_table1_stmt1_outer;
go

EXEC insert_test_table1_stmt2_outer;
go

DROP PROC insert_test_table1_stmt1_outer;
go

EXEC insert_test_table1_stmt2_outer;
go

SET IDENTITY_INSERT test_table1 OFF;
go

EXEC insert_test_table1_stmt2_outer;
go

SELECT * FROM test_table1;
go

-- Test after arbitrarily changing state
SET IDENTITY_INSERT test_table2 ON;
go

EXEC insert_test_table1_stmt1;
go

EXEC insert_test_table1_stmt2;
go

SET IDENTITY_INSERT test_table2 ON;
go

SET IDENTITY_INSERT test_table2 OFF;
go

SET IDENTITY_INSERT test_table2 OFF;
go

EXEC insert_test_table1_stmt1;
go

EXEC insert_test_table1_stmt2;
go

SET IDENTITY_INSERT test_table1 ON;
go

SET IDENTITY_INSERT test_table1 OFF;
go

EXEC insert_test_table1_stmt1;
go

EXEC insert_test_table1_stmt2;
go

SET IDENTITY_INSERT test_table1 ON;
go

EXEC insert_test_table1_stmt1;
go

SET IDENTITY_INSERT test_table1 ON;
go

EXEC insert_test_table1_stmt2;
go

SET IDENTITY_INSERT test_table1 OFF;
go

EXEC insert_test_table1_stmt1;
go

EXEC insert_test_table1_stmt2;
go

SELECT * FROM test_table1;
go

-- Clean up
DROP PROC insert_test_table1_stmt1,
insert_test_table1_stmt2,
insert_test_table1_stmt2_outer,
insert_test_table1_stmt3,
insert_test_table1_stmt4,
insert_test_table1_stmt5,
insert_test_table1_stmt6,
insert_test_table1_test_multi_stmts,
insert_test_table1_val;
go
DROP TABLE test_table1,
test_table2;
go
