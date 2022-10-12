CREATE TABLE babel_3010_vu_prepare_t1(a INT);
GO

CREATE PROCEDURE babel_3010_vu_prepare_p1 @a INT AS SELECT @a;
GO

CREATE PROCEDURE babel_3010_vu_prepare_p2 @a INT = 1, @b CHAR(2) AS SELECT @a, @b;
GO

-- Simple function
CREATE FUNCTION babel_3010_vu_prepare_f1(@a INT) RETURNS INT AS BEGIN RETURN @a END;
GO

-- Overloaded function
CREATE FUNCTION babel_3010_vu_prepare_f1(@a int, @b varchar(10)) RETURNS INT AS BEGIN RETURN @a END;
GO

-- ITVF
CREATE FUNCTION babel_3010_vu_prepare_f2(@a INT)
RETURNS TABLE
	AS RETURN (
		SELECT * FROM babel_3010_vu_prepare_t1 WHERE a = @a
	);
GO

-- MSTVF
CREATE FUNCTION babel_3010_vu_prepare_f3(@a INT)
RETURNS @tab TABLE (a int, b varchar(10))
	AS BEGIN
		INSERT INTO @tab VALUES(1, 'abc');
		RETURN;
	END;
GO

CREATE VIEW babel_3010_vu_prepare_v1
AS SELECT sys.babelfish_get_pltsql_function_signature(oid)
FROM pg_catalog.pg_proc WHERE proname = 'babel_3010_vu_prepare_f1' ORDER BY proname;
GO

CREATE TRIGGER babel_3010_vu_prepare_trig1 ON babel_3010_vu_prepare_t1
AFTER DELETE AS
	SELECT @@ROWCOUNT;
GO

CREATE TRIGGER babel_3010_vu_prepare_trig2 ON babel_3010_vu_prepare_t1
AFTER UPDATE AS
	SELECT @@ROWCOUNT;
GO

CREATE TRIGGER babel_3010_vu_prepare_trig3 ON babel_3010_vu_prepare_t1
AFTER INSERT AS
	SELECT @@ROWCOUNT;
GO

CREATE TRIGGER babel_3010_vu_prepare_trig4 ON babel_3010_vu_prepare_t1
FOR INSERT AS
	SELECT @@ROWCOUNT;
GO

CREATE TYPE babel_3010_vu_prepare_typ1 AS TABLE (a int);
GO
