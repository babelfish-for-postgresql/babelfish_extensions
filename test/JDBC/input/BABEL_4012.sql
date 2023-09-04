CREATE SCHEMA BABEL_4012_sch
GO

CREATE TABLE BABEL_4012_sch.table1(a int, b int);
GO

INSERT INTO BABEL_4012_sch.table1 VALUES(1,4), (1,5);
GO

-- WITH ALIAS
-- without qouted identifier in alias
-- with schema name in set and update
UPDATE BABEL_4012_sch.table1 SET BABEL_4012_sch.table1.a = 2 FROM BABEL_4012_sch.table1 AS t1
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- with schema name in set and not in update
UPDATE table1 SET BABEL_4012_sch.table1.a = 3 FROM BABEL_4012_sch.table1 AS t1
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- with schema name in set and alias in update
UPDATE t1 SET BABEL_4012_sch.table1.a = 1 FROM BABEL_4012_sch.table1 AS t1
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- with schema name in update and not in set
UPDATE BABEL_4012_sch.table1 SET table1.a = 2 FROM BABEL_4012_sch.table1 AS t1
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- without schema in update and set
UPDATE table1 SET table1.a = 3 FROM BABEL_4012_sch.table1 AS t1
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- without schema name in set and alias in update
UPDATE t1 SET table1.a = 1 FROM BABEL_4012_sch.table1 AS t1
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- using alias in set and schema in update
UPDATE BABEL_4012_sch.table1 SET t1.a = 2 FROM BABEL_4012_sch.table1 AS t1
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- using alias in set and without schema in update
UPDATE table1 SET t1.a = 3 FROM BABEL_4012_sch.table1 AS t1
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- using alias in set and update
UPDATE t1 SET t1.a = 1 FROM BABEL_4012_sch.table1 AS t1
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- using alias in set and update
UPDATE t1 SET t1.a = 2 FROM BABEL_4012_sch.table1 AS t1
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- WITH ALIAS
-- with qouted identifier in alias
-- with schema name in set and update
UPDATE BABEL_4012_sch.table1 SET BABEL_4012_sch.table1.a = 3 FROM BABEL_4012_sch.table1 AS "_t1 AbC か₰₨"
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- with schema name in set and not in update
UPDATE table1 SET BABEL_4012_sch.table1.a = 2 FROM BABEL_4012_sch.table1 AS  "_t1 AbC か₰₨"
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- with schema name in set and alias in update
UPDATE  "_t1 AbC か₰₨" SET BABEL_4012_sch.table1.a = 1 FROM BABEL_4012_sch.table1 AS  "_t1 AbC か₰₨"
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- with schema name in update and not in set
UPDATE BABEL_4012_sch.table1 SET table1.a = 3 FROM BABEL_4012_sch.table1 AS  "_t1 AbC か₰₨"
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- without schema in update and set
UPDATE table1 SET table1.a = 2 FROM BABEL_4012_sch.table1 AS  "_t1 AbC か₰₨"
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- without schema name in set and alias in update
UPDATE  "_t1 AbC か₰₨" SET table1.a = 1 FROM BABEL_4012_sch.table1 AS  "_t1 AbC か₰₨"
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- using alias in set and schema in update
UPDATE BABEL_4012_sch.table1 SET "_t1 AbC か₰₨".a = 3 FROM BABEL_4012_sch.table1 AS  "_t1 AbC か₰₨"
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- using alias in set and without schema in update
UPDATE table1 SET "_t1 AbC か₰₨".a = 2 FROM BABEL_4012_sch.table1 AS "_t1 AbC か₰₨"
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- using alias in set and update
UPDATE "_t1 AbC か₰₨" SET "_t1 AbC か₰₨".a = 1 FROM BABEL_4012_sch.table1 AS "_t1 AbC か₰₨"
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- using alias in set and update
UPDATE "_t1 AbC か₰₨" SET "_t1 AbC か₰₨".a = 2 FROM BABEL_4012_sch.table1 AS "_t1 AbC か₰₨"
GO

SELECT * FROM BABEL_4012_sch.table1;
GO





-- WITHOUT ALIAS
-- with schema name in set and update
UPDATE BABEL_4012_sch.table1 SET BABEL_4012_sch.table1.a = 3 FROM BABEL_4012_sch.table1
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- with schema name in set and not in update
UPDATE table1 SET BABEL_4012_sch.table1.a = 1 FROM BABEL_4012_sch.table1
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- with schema name in update and not in set
UPDATE BABEL_4012_sch.table1 SET table1.a = 2 FROM BABEL_4012_sch.table1
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- without schema in update and set
UPDATE table1 SET table1.a = 3 FROM BABEL_4012_sch.table1
GO

SELECT * FROM BABEL_4012_sch.table1;
GO

-- DEFAULT SCHEMA
CREATE TABLE BABEL_4012_table2(a int, b int);
GO

INSERT INTO BABEL_4012_table2 VALUES(1,6), (1,7);
GO

-- WITH ALIAS
-- with schema name in set and update
-- error expected
UPDATE dbo.BABEL_4012_table2 SET dbo.BABEL_4012_table2.a = 2 FROM BABEL_4012_table2 AS t1
GO

SELECT * FROM BABEL_4012_table2;
GO

-- with schema name in set and not in update
UPDATE BABEL_4012_table2 SET dbo.BABEL_4012_table2.a = 3 FROM BABEL_4012_table2 AS t1
GO

SELECT * FROM BABEL_4012_table2;
GO

-- with schema name in set and alias in update
UPDATE t1 SET dbo.BABEL_4012_table2.a = 1 FROM BABEL_4012_table2 AS t1
GO

SELECT * FROM BABEL_4012_table2;
GO

-- with schema name in update and not in set
-- error expected
UPDATE dbo.BABEL_4012_table2 SET BABEL_4012_table2.a = 2 FROM BABEL_4012_table2 AS t1
GO

SELECT * FROM BABEL_4012_table2;
GO

-- without schema in update and set
UPDATE BABEL_4012_table2 SET BABEL_4012_table2.a = 3 FROM BABEL_4012_table2 AS t1
GO

SELECT * FROM BABEL_4012_table2;
GO

-- without schema name in set and alias in update
UPDATE t1 SET BABEL_4012_table2.a = 1 FROM BABEL_4012_table2 AS t1
GO

SELECT * FROM BABEL_4012_table2;
GO

-- using alias in set and schema in update
-- error expected
UPDATE dbo.BABEL_4012_table2 SET t1.a = 2 FROM BABEL_4012_table2 AS t1
GO

SELECT * FROM BABEL_4012_table2;
GO

-- using alias in set and without schema in update
UPDATE BABEL_4012_table2 SET t1.a = 3 FROM BABEL_4012_table2 AS t1
GO

SELECT * FROM BABEL_4012_table2;
GO

-- using alias in set and update
UPDATE t1 SET t1.a = 1 FROM BABEL_4012_table2 AS t1
GO

SELECT * FROM BABEL_4012_table2;
GO

-- using alias in set and update
UPDATE t1 SET t1.a = 2 FROM BABEL_4012_table2 AS t1
GO

SELECT * FROM BABEL_4012_table2;
GO


-- WITHOUT ALIAS
-- with schema name in set and update
UPDATE dbo.BABEL_4012_table2 SET dbo.BABEL_4012_table2.a = 3 FROM dbo.BABEL_4012_table2
GO

SELECT * FROM dbo.BABEL_4012_table2;
GO

-- with schema name in set and not in update
UPDATE BABEL_4012_table2 SET dbo.BABEL_4012_table2.a = 1 FROM dbo.BABEL_4012_table2
GO

SELECT * FROM dbo.BABEL_4012_table2;
GO

-- with schema name in update and not in set
UPDATE dbo.BABEL_4012_table2 SET BABEL_4012_table2.a = 2 FROM dbo.BABEL_4012_table2
GO

SELECT * FROM dbo.BABEL_4012_table2;
GO

-- without schema in update and set
UPDATE BABEL_4012_table2 SET BABEL_4012_table2.a = 3 FROM dbo.BABEL_4012_table2
GO

SELECT * FROM dbo.BABEL_4012_table2;
GO



-- CLEAR
DROP TABLE BABEL_4012_table2;
GO

DROP TABLE BABEL_4012_sch.table1;
GO

DROP SCHEMA BABEL_4012_sch;
GO