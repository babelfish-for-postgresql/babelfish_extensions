CREATE DATABASE babel_3201_db1;
GO

CREATE SCHEMA babel_3201_sch1;
GO

CREATE TABLE babel_3201_t1( a int identity, b int);
GO

CREATE TABLE babel_3201_sch1.babel_3201_t2(a varchar(20), b int identity);
GO

INSERT INTO babel_3201_t1 VALUES (1);
GO

INSERT INTO babel_3201_sch1.babel_3201_t2 VALUES ('string 1');
GO
