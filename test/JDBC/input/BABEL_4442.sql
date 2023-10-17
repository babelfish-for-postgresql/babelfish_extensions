CREATE SCHEMA babel_4442_s1
GO
CREATE SCHEMA babel_4442_s2
GO

CREATE TABLE babel_4442_t (id INT)
GO
CREATE TABLE babel_4442_s1.babel_4442_t (id INT)
GO
CREATE TABLE babel_4442_s2.babel_4442_t (id INT)
GO

INSERT INTO babel_4442_t VALUES (1)
GO
INSERT INTO babel_4442_s1.babel_4442_t VALUES (2), (3)
GO
INSERT INTO babel_4442_s2.babel_4442_t VALUES (3), (4), (5)
GO

CREATE FUNCTION babel_4442_f() RETURNS INT AS
BEGIN
    RETURN (SELECT COUNT(*) FROM babel_4442_t)
END
GO

CREATE FUNCTION babel_4442_s1.babel_4442_f() RETURNS INT AS
BEGIN
    RETURN (SELECT COUNT(*) FROM babel_4442_t)
END
GO

CREATE FUNCTION babel_4442_s2.babel_4442_f() RETURNS INT AS
BEGIN
    RETURN (SELECT COUNT(*) FROM babel_4442_t)
END
GO

SELECT TABLE_NAME, TABLE_TYPE FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = SCHEMA_NAME() and TABLE_NAME = 'babel_4442_t'
GO

SELECT babel_4442_f(), * FROM babel_4442_s1.babel_4442_t
GO

SELECT babel_4442_f(), babel_4442_s1.babel_4442_f(), babel_4442_s2.babel_4442_f(), * FROM babel_4442_s1.babel_4442_t
GO

SELECT babel_4442_f(), babel_4442_s1.babel_4442_f(), babel_4442_s2.babel_4442_f(), * FROM babel_4442_t
GO

SELECT babel_4442_f(), current_setting('search_path'), babel_4442_s1.babel_4442_f(), current_setting('search_path'),
        babel_4442_s2.babel_4442_f(), 1, current_setting('search_path'), * FROM babel_4442_t
GO

SELECT current_setting('search_path')
GO

BEGIN TRANSACTION
GO
SELECT current_setting('search_path')
GO
SELECT babel_4442_s1.babel_4442_f(), babel_4442_s2.babel_4442_f(), * FROM babel_4442_t
GO
SELECT current_setting('search_path')
GO
SELECT babel_4442_s1.babel_4442_f(), babel_4442_s2.babel_4442_f(), * FROM babel_4442_t
GO
COMMIT
GO

SELECT current_setting('search_path')
GO

BEGIN TRANSACTION
GO
SELECT current_setting('search_path')
GO
SELECT babel_4442_s1.babel_4442_f(), babel_4442_s2.babel_4442_f(), * FROM babel_4442_t
GO
SELECT current_setting('search_path')
GO
SELECT babel_4442_s1.babel_4442_f(), babel_4442_s2.babel_4442_f(), * FROM babel_4442_t
GO
ROLLBACK
GO

SELECT current_setting('search_path')
GO

DROP TABLE IF EXISTS babel_4442_t, babel_4442_s1.babel_4442_t, babel_4442_s2.babel_4442_t
GO
DROP FUNCTION IF EXISTS babel_4442_f, babel_4442_s1.babel_4442_f, babel_4442_s2.babel_4442_f
GO
DROP SCHEMA babel_4442_s1
GO
DROP SCHEMA babel_4442_s2
GO
