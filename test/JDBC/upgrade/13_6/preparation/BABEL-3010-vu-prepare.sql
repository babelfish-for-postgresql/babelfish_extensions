CREATE TABLE babel_3010_vu_prepare_t1(a INT);
GO

CREATE PROCEDURE babel_3010_vu_prepare_p1 @a INT AS SELECT @a;
GO

CREATE PROCEDURE babel_3010_vu_prepare_p2 @a INT = 1, @b CHAR(2) AS SELECT @a, @b;
GO

CREATE FUNCTION babel_3010_vu_prepare_f1(@a INT) RETURNS INT AS BEGIN RETURN @a END;
GO

CREATE VIEW babel_3010_vu_prepare_v1 AS SELECT * FROM babel_3010_vu_prepare_t1;
GO

CREATE TRIGGER babel_3010_vu_prepare_trig1 ON babel_3010_vu_prepare_t1
AFTER DELETE AS
	SELECT @@ROWCOUNT;
GO

CREATE TYPE babel_3010_vu_prepare_typ1 AS TABLE (a int);
GO