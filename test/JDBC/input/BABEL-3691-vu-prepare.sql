-- DIFFERENT CASES TO CHECK DATATYPES
-- Exact Numerics
CREATE TABLE BABEL_3691_vu_prepare_t1(a bigint, b bit, c decimal, d int, e money, f numeric, g smallint, h smallmoney, i tinyint)
GO
INSERT BABEL_3691_vu_prepare_t1 VALUES(9223372036854775807, 1, 123.2, 2147483647, 3148.29, 12345.12, 32767, 3148.29, 255)
GO

-- Approximate numerics
CREATE TABLE BABEL_3691_vu_prepare_t2(a float, b real)
GO
INSERT BABEL_3691_vu_prepare_t2 VALUES(12.05, 120.53)
GO

-- Date and time
CREATE TABLE BABEL_3691_vu_prepare_t3(a time, b date, c smalldatetime, d datetime, e datetime2, f datetimeoffset)
GO
INSERT BABEL_3691_vu_prepare_t3 VALUES('2022-11-11 23:17:08.560','2022-11-11 23:17:08.560','2022-11-11 23:17:08.560','2022-11-11 23:17:08.560','2022-11-11 23:17:08.560','2022-11-11 23:17:08.560')
GO

-- Character strings
CREATE TABLE BABEL_3691_vu_prepare_t4(a char, b varchar(3), c text)
GO
INSERT BABEL_3691_vu_prepare_t4 VALUES('a','abc','abc')
GO

-- Unicode character strings
CREATE TABLE BABEL_3691_vu_prepare_t5(a nchar(5), b nvarchar(5), c ntext)
GO
INSERT BABEL_3691_vu_prepare_t5 VALUES('abc','abc','abc')
GO

-- Binary strings
CREATE TABLE BABEL_3691_vu_prepare_t6(a binary, b varbinary(10))
GO
INSERT BABEL_3691_vu_prepare_t6 VALUES (123456,0x0a0b0c0d0e)
GO

-- Return null string
CREATE TABLE BABEL_3691_vu_prepare_t7(MyColumn int)
GO

-- Rowversion and timestamp
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
GO

CREATE TABLE BABEL_3691_vu_prepare_t8 (myKey int, myValue int,RV rowversion);
GO
INSERT INTO BABEL_3691_vu_prepare_t8 (myKey, myValue) VALUES (1, 0);
GO

CREATE TABLE BABEL_3691_vu_prepare_t9 (myKey int, myValue int, timestamp);
GO
INSERT INTO BABEL_3691_vu_prepare_t9 (myKey, myValue) VALUES (1, 0);
GO


-- Exact Numerics
CREATE VIEW BABEL_3691_vu_prepare_view1 AS
SELECT a, c, d, f, g, i 
FROM BABEL_3691_vu_prepare_t1
FOR JSON PATH;
GO

CREATE VIEW BABEL_3691_vu_prepare_view2 AS
SELECT b 
FROM BABEL_3691_vu_prepare_t1
FOR JSON PATH;
GO

CREATE VIEW BABEL_3691_vu_prepare_view3 AS
SELECT e 
FROM BABEL_3691_vu_prepare_t1
FOR JSON PATH;
GO

CREATE VIEW BABEL_3691_vu_prepare_view4 AS
SELECT h
FROM BABEL_3691_vu_prepare_t1
FOR JSON PATH;
GO

-- Approximate numerics
CREATE VIEW BABEL_3691_vu_prepare_view5 AS
SELECT *
FROM BABEL_3691_vu_prepare_t2
FOR JSON PATH;
GO

-- Date and time
CREATE VIEW BABEL_3691_vu_prepare_view6 AS
SELECT a,b 
FROM BABEL_3691_vu_prepare_t3
FOR JSON PATH;
GO

CREATE VIEW BABEL_3691_vu_prepare_view7 AS
SELECT c
FROM BABEL_3691_vu_prepare_t3
FOR JSON PATH;
GO

CREATE VIEW BABEL_3691_vu_prepare_view8 AS
SELECT d 
FROM BABEL_3691_vu_prepare_t3
FOR JSON PATH;
GO

CREATE VIEW BABEL_3691_vu_prepare_view9 AS
SELECT e 
FROM BABEL_3691_vu_prepare_t3
FOR JSON PATH;
GO

CREATE VIEW BABEL_3691_vu_prepare_view10 AS
SELECT f 
FROM BABEL_3691_vu_prepare_t3
FOR JSON PATH;
GO

-- Character strings
CREATE VIEW BABEL_3691_vu_prepare_view11 AS
SELECT * 
FROM BABEL_3691_vu_prepare_t4
FOR JSON PATH;
GO

-- Unicode character strings
CREATE VIEW BABEL_3691_vu_prepare_view12 AS
SELECT * 
FROM BABEL_3691_vu_prepare_t5
FOR JSON PATH;
GO

-- Binary strings
CREATE VIEW BABEL_3691_vu_prepare_view13 AS
SELECT a 
FROM BABEL_3691_vu_prepare_t6
FOR JSON PATH;
GO

CREATE VIEW BABEL_3691_vu_prepare_view14 AS
SELECT b
FROM BABEL_3691_vu_prepare_t6
FOR JSON PATH;
GO

-- Return null string
CREATE VIEW BABEL_3691_vu_prepare_view15 AS
SELECT *
FROM BABEL_3691_vu_prepare_t7
FOR JSON PATH;
GO

-- Rowversion and timestamp
CREATE VIEW BABEL_3691_vu_prepare_view16 AS
SELECT *
FROM BABEL_3691_vu_prepare_t8
FOR JSON PATH;
GO

CREATE VIEW BABEL_3691_vu_prepare_view17 AS
SELECT *
FROM BABEL_3691_vu_prepare_t9
FOR JSON PATH;
GO
