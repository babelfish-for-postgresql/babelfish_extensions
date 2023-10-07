CREATE DATABASE db1
GO

CREATE SCHEMA s1
GO
CREATE SCHEMA s2
GO

CREATE TABLE t (id int)
GO
CREATE TABLE s1.t (id int)
GO
CREATE TABLE s2.t (id int)
GO

INSERT INTO t VALUES (1)
GO
INSERT INTO s1.t VALUES (2), (3)
GO
INSERT INTO s2.t VALUES (3), (4), (5)
GO

CREATE FUNCTION f() RETURNS INT AS
BEGIN
    RETURN (SELECT COUNT(*) FROM t)
END
GO

CREATE FUNCTION s1.f() RETURNS INT AS
BEGIN
    RETURN (SELECT COUNT(*) FROM t)
END
GO

CREATE FUNCTION s2.f() RETURNS INT AS
BEGIN
    RETURN (SELECT COUNT(*) FROM t)
END
GO

CREATE FUNCTION s2.f_new() RETURNS INT AS
BEGIN
    RETURN (SELECT s1.f())
END
GO

SELECT TABLE_NAME, TABLE_TYPE FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = SCHEMA_NAME() and TABLE_NAME = 't'
GO

SELECT f(), * FROM s1.t
GO

SELECT f(), s1.f(), s2.f(), * FROM s1.t
GO

SELECT f(), s1.f(), s2.f(), * FROM t
GO

SELECT f(), current_setting('search_path'), s1.f(), current_setting('search_path'),
        s2.f(), 1, current_setting('search_path'), * FROM t
GO

SELECT current_setting('search_path')
GO

BEGIN TRANSACTION
GO
SELECT current_setting('search_path')
GO
SELECT s1.f(), s2.f(), * FROM t
GO
SELECT current_setting('search_path')
GO
SELECT s1.f(), s2.f(), * FROM t
GO
COMMIT
GO

SELECT current_setting('search_path')
GO

BEGIN TRANSACTION
GO
SELECT current_setting('search_path')
GO
SELECT s1.f(), s2.f(), * FROM t
GO
SELECT current_setting('search_path')
GO
SELECT s1.f(), s2.f(), * FROM t
GO
ROLLBACK
GO

SELECT current_setting('search_path')
GO

DROP DATABASE db1
GO
DROP TABLE IF EXISTS t, s1.t, s2.t
GO
DROP FUNCTION IF EXISTS f, s1.f, s2.f, s2.f_new
GO
DROP SCHEMA s1
GO
DROP SCHEMA s2
GO
