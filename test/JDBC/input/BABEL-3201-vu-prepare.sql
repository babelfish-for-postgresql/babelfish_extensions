CREATE DATABASE babel_3201_db1;
GO

CREATE SCHEMA babel_3201_sch1;
GO

CREATE TABLE babel_3201_sch1.babel_3201_t2(a varchar(20), b int identity);
GO

CREATE TABLE babel_3201_t_int( a int identity, b int);
GO

CREATE TABLE babel_3201_t_tinyint( a tinyint identity(5,1), b int);
GO

CREATE TABLE babel_3201_t_smallint( a smallint identity(10,10), b int);
GO

CREATE TABLE babel_3201_t_bigint( a bigint identity(3,3), b int);
GO

CREATE TABLE babel_3201_t_numeric( a numeric identity(4,2), b int);
GO

CREATE TABLE babel_3201_t_decimal( a decimal identity(7,3), b int);
GO

CREATE TABLE babel_3201_t1( a int identity, b int);
GO

CREATE TABLE babel_3201_t2( a int, b int);
GO

INSERT INTO babel_3201_sch1.babel_3201_t2 VALUES ('string 1');
GO

INSERT INTO babel_3201_t_tinyint VALUES (5);
GO

INSERT INTO babel_3201_t_tinyint VALUES (6);
GO

INSERT INTO babel_3201_t_tinyint VALUES (7);
GO

INSERT INTO babel_3201_t_smallint VALUES (5);
GO

INSERT INTO babel_3201_t_smallint VALUES (6);
GO

INSERT INTO babel_3201_t_smallint VALUES (7);
GO

INSERT INTO babel_3201_t_int VALUES (5);
GO

INSERT INTO babel_3201_t_int VALUES (6);
GO

INSERT INTO babel_3201_t_int VALUES (7);
GO

INSERT INTO babel_3201_t_bigint VALUES (5);
GO

INSERT INTO babel_3201_t_bigint VALUES (6);
GO

INSERT INTO babel_3201_t_bigint VALUES (6);
GO

INSERT INTO babel_3201_t_numeric VALUES (5);
GO

INSERT INTO babel_3201_t_numeric VALUES (6);
GO

INSERT INTO babel_3201_t_numeric VALUES (7);
GO

INSERT INTO babel_3201_t_decimal VALUES (5);
GO

INSERT INTO babel_3201_t_decimal VALUES (6);
GO

INSERT INTO babel_3201_t_decimal VALUES (7);
GO

CREATE PROCEDURE babel_3201_proc1
AS
DBCC CHECKIDENT(babel_3201_t_tinyint, RESEED, 30)
GO

CREATE PROCEDURE babel_3201_proc2
AS
DBCC CHECKIDENT(babel_3201_t_tinyint, RESEED, 257)
GO

CREATE LOGIN babel_3201_log1 WITH PASSWORD='12345678';
GO

USE babel_3201_db1;
GO

GRANT CONNECT TO guest;
GO
