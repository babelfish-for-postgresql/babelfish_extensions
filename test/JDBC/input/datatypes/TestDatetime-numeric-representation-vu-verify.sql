-- output from SQL Server :
-- 1900-01-02 00:00:00.000	1900-01-04 00:00:00.000	1900-01-03 12:00:00.000	1900-01-03 12:00:00.000	1900-01-03 12:00:00.000	1900-01-03 00:00:00.000	1900-01-03 00:00:00.000	1900-01-03 00:00:00.000	1900-01-03 00:00:00.000	1900-01-03 12:00:00.000	1900-01-03 12:00:00.000	1900-01-02 00:00:00.000	1899-12-29 00:00:00.000	1899-12-29 12:00:00.000	1899-12-29 12:00:00.000	1899-12-29 12:00:00.000	1899-12-30 00:00:00.000	1899-12-30 00:00:00.000	1899-12-30 00:00:00.000	1899-12-29 12:00:00.000	1899-12-29 12:00:00.000	null
SELECT * FROM Datetime_view1
GO
DROP VIEW Datetime_view1
GO

-- output from SQL Server :
-- 1900-01-02 00:00	1900-01-04 00:00	1900-01-03 12:00	1900-01-03 12:00	1900-01-03 12:00	1900-01-03 00:00	1900-01-03 00:00	1900-01-03 00:00	1900-01-03 00:00	1900-01-03 12:00	1900-01-03 12:00	1900-01-02 00:00	null
SELECT * FROM Datetime_view2
GO
DROP VIEW Datetime_view2
GO

-- output from SQL Server :
-- 0	2880	2160	2160	2160	1440	1440	1440	1440	2160	-5040	0	-2880	-2160	-2160	-2160	-1440	-1440	-1440	-2160	-2160
SELECT * FROM Datetime_view6
GO
DROP VIEW Datetime_view6
GO

-- Operators
SELECT * FROM Datetime_Operators_tbl1 WHERE col = CAST(4 as BIT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col > CAST(4 as BIT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col >= CAST(4 as BIT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col < CAST(4 as BIT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col <= CAST(4 as BIT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col != CAST(4 as BIT);
GO

SELECT * FROM Datetime_Operators_tbl1 WHERE col = CAST(4 as DECIMAL);
SELECT * FROM Datetime_Operators_tbl1 WHERE col > CAST(4 as DECIMAL);
SELECT * FROM Datetime_Operators_tbl1 WHERE col >= CAST(4 as DECIMAL);
SELECT * FROM Datetime_Operators_tbl1 WHERE col < CAST(4 as DECIMAL);
SELECT * FROM Datetime_Operators_tbl1 WHERE col <= CAST(4 as DECIMAL);
SELECT * FROM Datetime_Operators_tbl1 WHERE col != CAST(4 as DECIMAL);
GO

SELECT * FROM Datetime_Operators_tbl1 WHERE col = CAST(4 as NUMERIC);
SELECT * FROM Datetime_Operators_tbl1 WHERE col > CAST(4 as NUMERIC);
SELECT * FROM Datetime_Operators_tbl1 WHERE col >= CAST(4 as NUMERIC);
SELECT * FROM Datetime_Operators_tbl1 WHERE col < CAST(4 as NUMERIC);
SELECT * FROM Datetime_Operators_tbl1 WHERE col <= CAST(4 as NUMERIC);
SELECT * FROM Datetime_Operators_tbl1 WHERE col != CAST(4 as NUMERIC);
GO

SELECT * FROM Datetime_Operators_tbl1 WHERE col = CAST(4 as FLOAT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col > CAST(4 as FLOAT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col >= CAST(4 as FLOAT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col < CAST(4 as FLOAT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col <= CAST(4 as FLOAT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col != CAST(4 as FLOAT);
GO

SELECT * FROM Datetime_Operators_tbl1 WHERE col = CAST(4 as REAL);
SELECT * FROM Datetime_Operators_tbl1 WHERE col > CAST(4 as REAL);
SELECT * FROM Datetime_Operators_tbl1 WHERE col >= CAST(4 as REAL);
SELECT * FROM Datetime_Operators_tbl1 WHERE col < CAST(4 as REAL);
SELECT * FROM Datetime_Operators_tbl1 WHERE col <= CAST(4 as REAL);
SELECT * FROM Datetime_Operators_tbl1 WHERE col != CAST(4 as REAL);
GO

SELECT * FROM Datetime_Operators_tbl1 WHERE col = CAST(4 as INT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col > CAST(4 as INT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col >= CAST(4 as INT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col < CAST(4 as INT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col <= CAST(4 as INT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col != CAST(4 as INT);
GO

SELECT * FROM Datetime_Operators_tbl1 WHERE col = CAST(4 as BIGINT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col > CAST(4 as BIGINT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col >= CAST(4 as BIGINT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col < CAST(4 as BIGINT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col <= CAST(4 as BIGINT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col != CAST(4 as BIGINT);
GO

SELECT * FROM Datetime_Operators_tbl1 WHERE col = CAST(4 as SMALLINT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col > CAST(4 as SMALLINT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col >= CAST(4 as SMALLINT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col < CAST(4 as SMALLINT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col <= CAST(4 as SMALLINT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col != CAST(4 as SMALLINT);
GO

SELECT * FROM Datetime_Operators_tbl1 WHERE col = CAST(4 as TINYINT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col > CAST(4 as TINYINT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col >= CAST(4 as TINYINT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col < CAST(4 as TINYINT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col <= CAST(4 as TINYINT);
SELECT * FROM Datetime_Operators_tbl1 WHERE col != CAST(4 as TINYINT);
GO

SELECT * FROM Datetime_Operators_tbl1 WHERE col = CAST(4 as MONEY);
SELECT * FROM Datetime_Operators_tbl1 WHERE col > CAST(4 as MONEY);
SELECT * FROM Datetime_Operators_tbl1 WHERE col >= CAST(4 as MONEY);
SELECT * FROM Datetime_Operators_tbl1 WHERE col < CAST(4 as MONEY);
SELECT * FROM Datetime_Operators_tbl1 WHERE col <= CAST(4 as MONEY);
SELECT * FROM Datetime_Operators_tbl1 WHERE col != CAST(4 as MONEY);
GO

SELECT * FROM Datetime_Operators_tbl1 WHERE col = CAST(4 as SMALLMONEY);
SELECT * FROM Datetime_Operators_tbl1 WHERE col > CAST(4 as SMALLMONEY);
SELECT * FROM Datetime_Operators_tbl1 WHERE col >= CAST(4 as SMALLMONEY);
SELECT * FROM Datetime_Operators_tbl1 WHERE col < CAST(4 as SMALLMONEY);
SELECT * FROM Datetime_Operators_tbl1 WHERE col <= CAST(4 as SMALLMONEY);
SELECT * FROM Datetime_Operators_tbl1 WHERE col != CAST(4 as SMALLMONEY);
GO

SELECT * FROM Datetime_Operators_tbl1 WHERE col = NULL;
SELECT * FROM Datetime_Operators_tbl1 WHERE col > NULL;
SELECT * FROM Datetime_Operators_tbl1 WHERE col >= NULL;
SELECT * FROM Datetime_Operators_tbl1 WHERE col < NULL;
SELECT * FROM Datetime_Operators_tbl1 WHERE col <= NULL;
SELECT * FROM Datetime_Operators_tbl1 WHERE col != NULL;
GO

DROP TABLE Datetime_Operators_tbl1
GO

SELECT * FROM Datetime_Operators_tbl2 WHERE col = CAST(4 as BIT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col > CAST(4 as BIT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col >= CAST(4 as BIT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col < CAST(4 as BIT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col <= CAST(4 as BIT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col != CAST(4 as BIT);
GO

SELECT * FROM Datetime_Operators_tbl2 WHERE col = CAST(4 as DECIMAL);
SELECT * FROM Datetime_Operators_tbl2 WHERE col > CAST(4 as DECIMAL);
SELECT * FROM Datetime_Operators_tbl2 WHERE col >= CAST(4 as DECIMAL);
SELECT * FROM Datetime_Operators_tbl2 WHERE col < CAST(4 as DECIMAL);
SELECT * FROM Datetime_Operators_tbl2 WHERE col <= CAST(4 as DECIMAL);
SELECT * FROM Datetime_Operators_tbl2 WHERE col != CAST(4 as DECIMAL);
GO

SELECT * FROM Datetime_Operators_tbl2 WHERE col = CAST(4 as NUMERIC);
SELECT * FROM Datetime_Operators_tbl2 WHERE col > CAST(4 as NUMERIC);
SELECT * FROM Datetime_Operators_tbl2 WHERE col >= CAST(4 as NUMERIC);
SELECT * FROM Datetime_Operators_tbl2 WHERE col < CAST(4 as NUMERIC);
SELECT * FROM Datetime_Operators_tbl2 WHERE col <= CAST(4 as NUMERIC);
SELECT * FROM Datetime_Operators_tbl2 WHERE col != CAST(4 as NUMERIC);
GO

SELECT * FROM Datetime_Operators_tbl2 WHERE col = CAST(4 as FLOAT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col > CAST(4 as FLOAT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col >= CAST(4 as FLOAT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col < CAST(4 as FLOAT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col <= CAST(4 as FLOAT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col != CAST(4 as FLOAT);
GO

SELECT * FROM Datetime_Operators_tbl2 WHERE col = CAST(4 as REAL);
SELECT * FROM Datetime_Operators_tbl2 WHERE col > CAST(4 as REAL);
SELECT * FROM Datetime_Operators_tbl2 WHERE col >= CAST(4 as REAL);
SELECT * FROM Datetime_Operators_tbl2 WHERE col < CAST(4 as REAL);
SELECT * FROM Datetime_Operators_tbl2 WHERE col <= CAST(4 as REAL);
SELECT * FROM Datetime_Operators_tbl2 WHERE col != CAST(4 as REAL);
GO

SELECT * FROM Datetime_Operators_tbl2 WHERE col = CAST(4 as INT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col > CAST(4 as INT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col >= CAST(4 as INT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col < CAST(4 as INT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col <= CAST(4 as INT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col != CAST(4 as INT);
GO

SELECT * FROM Datetime_Operators_tbl2 WHERE col = CAST(4 as BIGINT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col > CAST(4 as BIGINT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col >= CAST(4 as BIGINT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col < CAST(4 as BIGINT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col <= CAST(4 as BIGINT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col != CAST(4 as BIGINT);
GO

SELECT * FROM Datetime_Operators_tbl2 WHERE col = CAST(4 as SMALLINT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col > CAST(4 as SMALLINT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col >= CAST(4 as SMALLINT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col < CAST(4 as SMALLINT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col <= CAST(4 as SMALLINT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col != CAST(4 as SMALLINT);
GO

SELECT * FROM Datetime_Operators_tbl2 WHERE col = CAST(4 as TINYINT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col > CAST(4 as TINYINT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col >= CAST(4 as TINYINT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col < CAST(4 as TINYINT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col <= CAST(4 as TINYINT);
SELECT * FROM Datetime_Operators_tbl2 WHERE col != CAST(4 as TINYINT);
GO

SELECT * FROM Datetime_Operators_tbl2 WHERE col = CAST(4 as MONEY);
SELECT * FROM Datetime_Operators_tbl2 WHERE col > CAST(4 as MONEY);
SELECT * FROM Datetime_Operators_tbl2 WHERE col >= CAST(4 as MONEY);
SELECT * FROM Datetime_Operators_tbl2 WHERE col < CAST(4 as MONEY);
SELECT * FROM Datetime_Operators_tbl2 WHERE col <= CAST(4 as MONEY);
SELECT * FROM Datetime_Operators_tbl2 WHERE col != CAST(4 as MONEY);
GO

SELECT * FROM Datetime_Operators_tbl2 WHERE col = CAST(4 as SMALLMONEY);
SELECT * FROM Datetime_Operators_tbl2 WHERE col > CAST(4 as SMALLMONEY);
SELECT * FROM Datetime_Operators_tbl2 WHERE col >= CAST(4 as SMALLMONEY);
SELECT * FROM Datetime_Operators_tbl2 WHERE col < CAST(4 as SMALLMONEY);
SELECT * FROM Datetime_Operators_tbl2 WHERE col <= CAST(4 as SMALLMONEY);
SELECT * FROM Datetime_Operators_tbl2 WHERE col != CAST(4 as SMALLMONEY);
GO

SELECT * FROM Datetime_Operators_tbl2 WHERE col = NULL;
SELECT * FROM Datetime_Operators_tbl2 WHERE col > NULL;
SELECT * FROM Datetime_Operators_tbl2 WHERE col >= NULL;
SELECT * FROM Datetime_Operators_tbl2 WHERE col < NULL;
SELECT * FROM Datetime_Operators_tbl2 WHERE col <= NULL;
SELECT * FROM Datetime_Operators_tbl2 WHERE col != NULL;
GO

DROP TABLE Datetime_Operators_tbl2
GO

-- Tables
ALTER TABLE Datetime_tbl1 ADD CONSTRAINT Datetime_constraint1 DEFAULT CAST(0 as BIT) FOR c1
INSERT INTO Datetime_tbl1 VALUES(DEFAULT)
INSERT INTO Datetime_tbl1 VALUES(CAST(1.5 as BIT))
GO
SELECT * FROM Datetime_tbl1
GO
DELETE FROM Datetime_tbl1 WHERE c1 IS NOT NULL
GO


ALTER TABLE Datetime_tbl1 ADD CONSTRAINT Datetime_constraint2 DEFAULT CAST(2 as DECIMAL) FOR c1
GO
INSERT INTO Datetime_tbl1 VALUES(DEFAULT)
INSERT INTO Datetime_tbl1 VALUES(CAST(1.5 as DECIMAL))
GO
SELECT * FROM Datetime_tbl1
GO
DELETE FROM Datetime_tbl1 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl1 ADD CONSTRAINT Datetime_constraint3 DEFAULT CAST(2 as NUMERIC) FOR c1
GO
INSERT INTO Datetime_tbl1 VALUES(DEFAULT)
INSERT INTO Datetime_tbl1 VALUES(CAST(1.5 as NUMERIC))
GO
SELECT * FROM Datetime_tbl1
GO
DELETE FROM Datetime_tbl1 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl1 ADD CONSTRAINT Datetime_constraint4 DEFAULT CAST(2 as FLOAT) FOR c1
GO
INSERT INTO Datetime_tbl1 VALUES(DEFAULT)
INSERT INTO Datetime_tbl1 VALUES(CAST(1.5 as FLOAT))
GO
SELECT * FROM Datetime_tbl1
GO
DELETE FROM Datetime_tbl1 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl1 ADD CONSTRAINT Datetime_constraint5 DEFAULT CAST(2 as REAL) FOR c1
GO
INSERT INTO Datetime_tbl1 VALUES(DEFAULT)
INSERT INTO Datetime_tbl1 VALUES(CAST(1.5 as REAL))
GO
SELECT * FROM Datetime_tbl1
GO
DELETE FROM Datetime_tbl1 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl1 ADD CONSTRAINT Datetime_constraint6 DEFAULT CAST(2 as INT) FOR c1
GO
INSERT INTO Datetime_tbl1 VALUES(DEFAULT)
INSERT INTO Datetime_tbl1 VALUES(CAST(1.5 as INT))
GO
SELECT * FROM Datetime_tbl1
GO
DELETE FROM Datetime_tbl1 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl1 ADD CONSTRAINT Datetime_constraint7 DEFAULT CAST(2 as BIGINT) FOR c1
GO
INSERT INTO Datetime_tbl1 VALUES(DEFAULT)
INSERT INTO Datetime_tbl1 VALUES(CAST(1.5 as BIGINT))
GO
SELECT * FROM Datetime_tbl1
GO
DELETE FROM Datetime_tbl1 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl1 ADD CONSTRAINT Datetime_constraint8 DEFAULT CAST(2 as SMALLINT) FOR c1
GO
INSERT INTO Datetime_tbl1 VALUES(DEFAULT)
INSERT INTO Datetime_tbl1 VALUES(CAST(1.5 as SMALLINT))
GO
SELECT * FROM Datetime_tbl1
GO
DELETE FROM Datetime_tbl1 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl1 ADD CONSTRAINT Datetime_constraint9 DEFAULT CAST(2 as TINYINT) FOR c1
GO
INSERT INTO Datetime_tbl1 VALUES(DEFAULT)
INSERT INTO Datetime_tbl1 VALUES(CAST(1.5 as TINYINT))
GO
SELECT * FROM Datetime_tbl1
GO
DELETE FROM Datetime_tbl1 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl1 ADD CONSTRAINT Datetime_constraint10 DEFAULT CAST(2 as MONEY) FOR c1
GO
INSERT INTO Datetime_tbl1 VALUES(DEFAULT)
INSERT INTO Datetime_tbl1 VALUES(CAST(1.5 as MONEY))
GO
SELECT * FROM Datetime_tbl1
GO
DELETE FROM Datetime_tbl1 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl1 ADD CONSTRAINT Datetime_constraint11 DEFAULT CAST(2 as SMALLMONEY) FOR c1
GO
INSERT INTO Datetime_tbl1 VALUES(DEFAULT)
INSERT INTO Datetime_tbl1 VALUES(CAST(1.5 as SMALLMONEY))
GO
SELECT * FROM Datetime_tbl1
GO
DELETE FROM Datetime_tbl1 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl1 ADD CONSTRAINT Datetime_constraint12 DEFAULT NULL FOR c1
GO
INSERT INTO Datetime_tbl1 VALUES(DEFAULT)
INSERT INTO Datetime_tbl1 VALUES(NULL)
GO
SELECT * FROM Datetime_tbl1
GO
DELETE FROM Datetime_tbl1 WHERE c1 IS NOT NULL
GO

DROP TABLE datetime_tbl1
GO

ALTER TABLE Datetime_tbl2 ADD CONSTRAINT Datetime_constraint13 DEFAULT CAST(0 as BIT) FOR c1
INSERT INTO Datetime_tbl2 VALUES(DEFAULT)
INSERT INTO Datetime_tbl2 VALUES(CAST(1.5 as BIT))
GO
SELECT * FROM Datetime_tbl2
GO
DELETE FROM Datetime_tbl2 WHERE c1 IS NOT NULL
GO


ALTER TABLE Datetime_tbl2 ADD CONSTRAINT Datetime_constraint14 DEFAULT CAST(2 as DECIMAL) FOR c1
GO
INSERT INTO Datetime_tbl2 VALUES(DEFAULT)
INSERT INTO Datetime_tbl2 VALUES(CAST(1.5 as DECIMAL))
GO
SELECT * FROM Datetime_tbl2
GO
DELETE FROM Datetime_tbl2 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl2 ADD CONSTRAINT Datetime_constraint15 DEFAULT CAST(2 as NUMERIC) FOR c1
GO
INSERT INTO Datetime_tbl2 VALUES(DEFAULT)
INSERT INTO Datetime_tbl2 VALUES(CAST(1.5 as NUMERIC))
GO
SELECT * FROM Datetime_tbl2
GO
DELETE FROM Datetime_tbl2 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl2 ADD CONSTRAINT Datetime_constrain16 DEFAULT CAST(2 as FLOAT) FOR c1
GO
INSERT INTO Datetime_tbl2 VALUES(DEFAULT)
INSERT INTO Datetime_tbl2 VALUES(CAST(1.5 as FLOAT))
GO
SELECT * FROM Datetime_tbl2
GO
DELETE FROM Datetime_tbl2 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl2 ADD CONSTRAINT Datetime_constraint17 DEFAULT CAST(2 as REAL) FOR c1
GO
INSERT INTO Datetime_tbl2 VALUES(DEFAULT)
INSERT INTO Datetime_tbl2 VALUES(CAST(1.5 as REAL))
GO
SELECT * FROM Datetime_tbl2
GO
DELETE FROM Datetime_tbl2 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl2 ADD CONSTRAINT Datetime_constraint18 DEFAULT CAST(2 as INT) FOR c1
GO
INSERT INTO Datetime_tbl2 VALUES(DEFAULT)
INSERT INTO Datetime_tbl2 VALUES(CAST(1.5 as INT))
GO
SELECT * FROM Datetime_tbl2
GO
DELETE FROM Datetime_tbl2 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl2 ADD CONSTRAINT Datetime_constraint19 DEFAULT CAST(2 as BIGINT) FOR c1
GO
INSERT INTO Datetime_tbl2 VALUES(DEFAULT)
INSERT INTO Datetime_tbl2 VALUES(CAST(1.5 as BIGINT))
GO
SELECT * FROM Datetime_tbl2
GO
DELETE FROM Datetime_tbl2 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl2 ADD CONSTRAINT Datetime_constraint20 DEFAULT CAST(2 as SMALLINT) FOR c1
GO
INSERT INTO Datetime_tbl2 VALUES(DEFAULT)
INSERT INTO Datetime_tbl2 VALUES(CAST(1.5 as SMALLINT))
GO
SELECT * FROM Datetime_tbl2
GO
DELETE FROM Datetime_tbl2 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl2 ADD CONSTRAINT Datetime_constraint21 DEFAULT CAST(2 as TINYINT) FOR c1
GO
INSERT INTO Datetime_tbl2 VALUES(DEFAULT)
INSERT INTO Datetime_tbl2 VALUES(CAST(1.5 as TINYINT))
GO
SELECT * FROM Datetime_tbl2
GO
DELETE FROM Datetime_tbl2 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl2 ADD CONSTRAINT Datetime_constraint22 DEFAULT CAST(2 as MONEY) FOR c1
GO
INSERT INTO Datetime_tbl2 VALUES(DEFAULT)
INSERT INTO Datetime_tbl2 VALUES(CAST(1.5 as MONEY))
GO
SELECT * FROM Datetime_tbl2
GO
DELETE FROM Datetime_tbl2 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl2 ADD CONSTRAINT Datetime_constraint23 DEFAULT CAST(2 as SMALLMONEY) FOR c1
GO
INSERT INTO Datetime_tbl2 VALUES(DEFAULT)
INSERT INTO Datetime_tbl2 VALUES(CAST(1.5 as SMALLMONEY))
GO
SELECT * FROM Datetime_tbl2
GO
DELETE FROM Datetime_tbl2 WHERE c1 IS NOT NULL
GO

ALTER TABLE Datetime_tbl2 ADD CONSTRAINT Datetime_constraint24 DEFAULT NULL FOR c1
GO
INSERT INTO Datetime_tbl2 VALUES(DEFAULT)
INSERT INTO Datetime_tbl2 VALUES(NULL)
GO
SELECT * FROM Datetime_tbl2
GO
DELETE FROM Datetime_tbl2 WHERE c1 IS NOT NULL
GO

DROP TABLE datetime_tbl2
GO

-- Procedures
EXEC Datetime_proc2 '1900-01-04 00:00:00', 3.1
GO
EXEC Datetime_proc2 '1900-01-01 00:00:00', 0
GO
EXEC Datetime_proc2 '1900-01-04 00:00:00', 2.5
GO
EXEC Datetime_proc2 '1899-12-29 00:00:00', -2.5
GO
DROP PROCEDURE Datetime_proc2
GO

EXEC Datetime_proc3 '1900-01-04 02:24:00', 3.1
GO
EXEC Datetime_proc3 '1900-01-01 00:00:00', 0
GO
EXEC Datetime_proc3 '1900-01-03 12:00:00', 2.5
GO
EXEC Datetime_proc3 '1899-12-29 12:00:00', -2.5
GO
DROP PROCEDURE Datetime_proc3
GO

EXEC Datetime_proc4 '1900-01-02 09:36:00', 1.4
GO
EXEC Datetime_proc4 '1900-01-04 02:24:00', 3.1
GO
EXEC Datetime_proc4 '1899-12-28 21:36:00', -3.1
GO
DROP PROCEDURE Datetime_proc4
GO

EXEC Datetime_proc5 '1900-01-02 09:35:59.997', 1.4
GO
EXEC Datetime_proc5 '1900-01-04 02:23:59.99', 3.1
GO
EXEC Datetime_proc5 '1900-01-01 00:00:00.000', 0
GO
EXEC Datetime_proc5 '1900-01-02 00:00:00.000', 1
GO
EXEC Datetime_proc5 '1899-12-28 21:36:00.007', -3.1
GO
DROP PROCEDURE Datetime_proc5
GO

EXEC Datetime_proc6 '1900-01-02 00:00:00.000', 1.4
GO
EXEC Datetime_proc6 '1900-01-04 00:00:00.000', 3.1
GO
EXEC Datetime_proc6 '1899-12-30 00:00:00.000', -2.5
GO
DROP PROCEDURE Datetime_proc6
GO

EXEC Datetime_proc7 '1900-01-02 00:00:00.000', 1.4
GO
EXEC Datetime_proc7 '1900-01-04 00:00:00.000', 3.1
GO
EXEC Datetime_proc7 '1899-12-30 00:00:00.000', -2.5
GO
DROP PROCEDURE Datetime_proc7
GO

EXEC Datetime_proc8 '1900-01-02 00:00:00.000', 1.4
GO
EXEC Datetime_proc8 '1989-09-18 00:00:00.000', 32767
GO
EXEC Datetime_proc8 '1989-09-18 00:00:00.000', 32768
GO
DROP PROCEDURE Datetime_proc8
GO

EXEC Datetime_proc9 '1900-01-02 00:00:00.000', 1.4
GO
EXEC Datetime_proc9 '1900-09-13 00:00:00.000', 255
GO
EXEC Datetime_proc9 '1900-09-13 00:00:00.000', 256
GO
DROP PROCEDURE Datetime_proc9
GO

EXEC Datetime_proc10 '1900-01-02 09:36:00.000', 1.4
GO
EXEC Datetime_proc10 '1900-01-04 02:24:00.000', 3.1
GO
EXEC Datetime_proc10 '1899-12-29 12:00:00.000', -2.5
GO
DROP PROCEDURE Datetime_proc10
GO

EXEC Datetime_proc11 '1900-01-02 09:36:00.000', 1.4
GO
EXEC Datetime_proc11 '1900-01-04 02:24:00.000', 3.1
GO
EXEC Datetime_proc11 '1899-12-29 12:00:00.000', -2.5
GO

EXEC Datetime_proc11 '1900-01-02 09:36:00.000', NULL
GO
EXEC Datetime_proc11 '1900-01-04 02:24:00.000', NULL
GO
DROP PROCEDURE Datetime_proc11
GO

EXEC SMALLDatetime_proc2 '1900-01-04 00:00:00', 3.1
GO
EXEC SMALLDatetime_proc2 '1900-01-01 00:00:00', 0
GO
EXEC SMALLDatetime_proc2 '1900-01-04 00:00:00', 2.5
GO
EXEC SMALLDatetime_proc2 '1899-12-29 00:00:00', -2.5
GO
DROP PROCEDURE SMALLDatetime_proc2
GO

EXEC SMALLDatetime_proc3 '1900-01-04 02:24:00', 3.1
GO
EXEC SMALLDatetime_proc3 '1900-01-01 00:00:00', 0
GO
EXEC SMALLDatetime_proc3 '1900-01-03 12:00:00', 2.5
GO
DROP PROCEDURE SMALLDatetime_proc3
GO

-- Incorrect 
EXEC SMALLDatetime_proc4 '1900-01-02 09:36:00', 1.4
GO
EXEC SMALLDatetime_proc4 '1900-01-04 02:24:00', 3.1
GO
EXEC SMALLDatetime_proc4 '1899-12-28 21:36:00', -3.1
GO
DROP PROCEDURE SMALLDatetime_proc4
GO

EXEC SMALLDatetime_proc5 '1900-01-02 09:35:59.997', 1.4
GO
EXEC SMALLDatetime_proc5 '1900-01-04 02:23:59.99', 3.1
GO
EXEC SMALLDatetime_proc5 '1900-01-01 00:00:00.000', 0
GO
EXEC SMALLDatetime_proc5 '1900-01-02 00:00:00.000', 1
GO
EXEC SMALLDatetime_proc5 '1899-12-28 21:36:00.007', -3.1
GO
DROP PROCEDURE SMALLDatetime_proc5
GO

EXEC SMALLDatetime_proc6 '1900-01-02 00:00:00.000', 1.4
GO
EXEC SMALLDatetime_proc6 '1900-01-04 00:00:00.000', 3.1
GO
EXEC SMALLDatetime_proc6 '1899-12-30 00:00:00.000', -2.5
GO
DROP PROCEDURE SMALLDatetime_proc6
GO

EXEC SMALLDatetime_proc7 '1900-01-02 00:00:00.000', 1.4
GO
EXEC SMALLDatetime_proc7 '1900-01-04 00:00:00.000', 3.1
GO
EXEC SMALLDatetime_proc7 '1899-12-30 00:00:00.000', -2.5
GO
DROP PROCEDURE SMALLDatetime_proc7
GO

EXEC SMALLDatetime_proc8 '1900-01-02 00:00:00.000', 1.4
GO
EXEC SMALLDatetime_proc8 '1989-09-18 00:00:00.000', 32767
GO
EXEC SMALLDatetime_proc8 '1989-09-18 00:00:00.000', 32768
GO
DROP PROCEDURE SMALLDatetime_proc8
GO

EXEC SMALLDatetime_proc9 '1900-01-02 00:00:00.000', 1.4
GO
EXEC SMALLDatetime_proc9 '1900-09-13 00:00:00.000', 255
GO
EXEC SMALLDatetime_proc9 '1900-09-13 00:00:00.000', 256
GO
DROP PROCEDURE SMALLDatetime_proc9
GO

-- Incorrect
EXEC SMALLDatetime_proc10 '1900-01-02 09:36:00.000', 1.4
GO
EXEC SMALLDatetime_proc10 '1900-01-04 02:24:00.000', 3.1
GO
EXEC SMALLDatetime_proc10 '1899-12-29 12:00:00.000', -2.5
GO
DROP PROCEDURE SMALLDatetime_proc10
GO


--Incorrect
EXEC SMALLDatetime_proc11 '1900-01-02 09:36:00.000', 1.4
GO
EXEC SMALLDatetime_proc11 '1900-01-04 02:24:00.000', 3.1
GO
EXEC SMALLDatetime_proc11 '1899-12-29 12:00:00.000', -2.5
GO

EXEC SMALLDatetime_proc11 '1900-01-02 09:36:00.000', NULL
GO
EXEC SMALLDatetime_proc11 '1900-01-04 02:24:00.000', NULL
GO
DROP PROCEDURE SMALLDatetime_proc11
GO

-- Union
SELECT datetimetype FROM Datetime_target_type_table UNION SELECT bittype FROM Datetime_source_type_table
GO

SELECT datetimetype FROM Datetime_target_type_table UNION SELECT decimaltype FROM Datetime_source_type_table
GO

SELECT datetimetype FROM Datetime_target_type_table UNION SELECT numerictype FROM Datetime_source_type_table
GO

SELECT datetimetype FROM Datetime_target_type_table UNION SELECT floattype FROM Datetime_source_type_table
GO

SELECT datetimetype FROM Datetime_target_type_table UNION SELECT realtype FROM Datetime_source_type_table
GO

SELECT datetimetype FROM Datetime_target_type_table UNION SELECT inttype FROM Datetime_source_type_table
GO

SELECT datetimetype FROM Datetime_target_type_table UNION SELECT biginttype FROM Datetime_source_type_table
GO

SELECT datetimetype FROM Datetime_target_type_table UNION SELECT smallinttype FROM Datetime_source_type_table
GO

SELECT datetimetype FROM Datetime_target_type_table UNION SELECT tinyinttype FROM Datetime_source_type_table
GO

SELECT datetimetype FROM Datetime_target_type_table UNION SELECT moneytype FROM Datetime_source_type_table
GO

SELECT datetimetype FROM Datetime_target_type_table UNION SELECT smallmonettype FROM Datetime_source_type_table
GO

SELECT datetimetype FROM Datetime_target_type_table UNION SELECT nulltype FROM Datetime_source_type_table
GO

SELECT smalldatetimetype FROM Datetime_target_type_table UNION SELECT bittype FROM Datetime_source_type_table
GO

SELECT smalldatetimetype FROM Datetime_target_type_table UNION SELECT decimaltype FROM Datetime_source_type_table
GO

SELECT smalldatetimetype FROM Datetime_target_type_table UNION SELECT numerictype FROM Datetime_source_type_table
GO

SELECT smalldatetimetype FROM Datetime_target_type_table UNION SELECT floattype FROM Datetime_source_type_table
GO

SELECT smalldatetimetype FROM Datetime_target_type_table UNION SELECT realtype FROM Datetime_source_type_table
GO

SELECT smalldatetimetype FROM Datetime_target_type_table UNION SELECT inttype FROM Datetime_source_type_table
GO

SELECT smalldatetimetype FROM Datetime_target_type_table UNION SELECT biginttype FROM Datetime_source_type_table
GO

SELECT smalldatetimetype FROM Datetime_target_type_table UNION SELECT smallinttype FROM Datetime_source_type_table
GO

SELECT smalldatetimetype FROM Datetime_target_type_table UNION SELECT tinyinttype FROM Datetime_source_type_table
GO

SELECT smalldatetimetype FROM Datetime_target_type_table UNION SELECT moneytype FROM Datetime_source_type_table
GO

SELECT smalldatetimetype FROM Datetime_target_type_table UNION SELECT smallmonettype FROM Datetime_source_type_table
GO

SELECT smalldatetimetype FROM Datetime_target_type_table UNION SELECT nulltype FROM Datetime_source_type_table
GO

DROP TABLE Datetime_target_type_table
GO

DROP TABLE Datetime_source_type_table
GO
