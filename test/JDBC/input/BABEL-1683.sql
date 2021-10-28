-- CREATE TABLE stmt
-- NVARCHAR(128)
CREATE TABLE babel_1683_table_nvarchar (a INT, b NVARCHAR(128))
go

INSERT INTO babel_1683_table_nvarchar VALUES (1, NULL)
go

INSERT INTO babel_1683_table_nvarchar(a) VALUES (2)
go

SELECT * FROM babel_1683_table_nvarchar
go

DROP TABLE babel_1683_table_nvarchar
go

-- SYSNAME not explicitly defined as NULL
CREATE TABLE babel_1683_table_sysname (a INT, b SYSNAME)
go

INSERT INTO babel_1683_table_sysname VALUES (1, NULL)
go

INSERT INTO babel_1683_table_sysname(a) VALUES (2)
go

SELECT * FROM babel_1683_table_sysname
go

DROP TABLE babel_1683_table_sysname
go

-- SYSNAME explicitly defined as NULL
CREATE TABLE babel_1683_table_sysname (a INT, b SYSNAME NULL)
go

INSERT INTO babel_1683_table_sysname VALUES (1, NULL)
go

INSERT INTO babel_1683_table_sysname(a) VALUES (2)
go

SELECT * FROM babel_1683_table_sysname
go

DROP TABLE babel_1683_table_sysname
go

-- ALTER TABLE ADD <column> stmt
-- NVARCHAR(128)
CREATE TABLE babel_1683_table_nvarchar (a INT)
go

ALTER TABLE babel_1683_table_nvarchar ADD b NVARCHAR(128)
go

INSERT INTO babel_1683_table_nvarchar VALUES (1, NULL)
go

INSERT INTO babel_1683_table_nvarchar(a) VALUES (2)
go

SELECT * FROM babel_1683_table_nvarchar
go

DROP TABLE babel_1683_table_nvarchar
go

-- SYSNAME not explicitly defined as NULL
CREATE TABLE babel_1683_table_sysname (a INT)
go

ALTER TABLE babel_1683_table_sysname ADD b SYSNAME
go

INSERT INTO babel_1683_table_sysname VALUES (1, NULL)
go

INSERT INTO babel_1683_table_sysname(a) VALUES (2)
go

SELECT * FROM babel_1683_table_sysname
go

DROP TABLE babel_1683_table_sysname
go

-- SYSNAME explicitly defined as NULL
CREATE TABLE babel_1683_table_sysname (a INT)
go

ALTER TABLE babel_1683_table_sysname ADD b SYSNAME NULL
go

INSERT INTO babel_1683_table_sysname VALUES (1, NULL)
go

INSERT INTO babel_1683_table_sysname(a) VALUES (2)
go

SELECT * FROM babel_1683_table_sysname
go

DROP TABLE babel_1683_table_sysname
go
