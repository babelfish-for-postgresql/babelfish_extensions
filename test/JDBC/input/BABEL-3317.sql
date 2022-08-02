/* batch statement. PARSEONLY must be turned off at parse
time so that the entire batch executes */
SET PARSEONLY ON;
go
CREATE TABLE babel_3317t1(a int);
INSERT INTO babel_3317t1 values (1);
SET PARSEONLY OFF;
SELECT * FROM babel_3317t1;
go

/* Test normal use */
SET PARSEONLY ON;
GO
INSERT INTO babel_3317t1 values (2);
GO
SET PARSEONLY OFF;
GO
SELECT * FROM babel_3317t1
GO

/* Test turning off multiple settings at once */
SET PARSEONLY ON;
SET FMTONLY, PARSEONLY OFF;
GO

SELECT * FROM babel_3317t1
GO

DROP TABLE babel_3317t1
GO

/* Parseonly can be set to true at parse time */
CREATE TABLE t3317(a int);
SET PARSEONLY ON;
GO

SET PARSEONLY OFF;
SELECT * FROM t3317;
GO

/* Test that syntax errors are still thrown with PARSEONLY on. */
SET PARSEONLY ON
GO

SELECT * FROM INSERT
GO

SET PARSEONLY OFF
GO

/* Test that we stop after parsing, no checking for existence of objects */

SET PARSEONLY ON
GO

/* Should not throw an error. */
SELECT * FROM fake_table_name
GO

SET PARSEONLY OFF
go
