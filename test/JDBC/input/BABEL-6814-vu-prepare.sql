CREATE TABLE babel_6814_t1(a int, b varchar(50));
GO

CREATE TABLE babel_6814_t2(c int, d varchar(50));
GO

CREATE INDEX babel_6814_idx1 ON babel_6814_t1(a);
GO

CREATE INDEX babel_6814_idx2 ON babel_6814_t1(b);
GO

CREATE INDEX babel_6814_idx3 ON babel_6814_t2(c);
GO

CREATE PROCEDURE babel_6814_proc1 AS SELECT 1;
GO

CREATE VIEW babel_6814_view1 AS SELECT * FROM babel_6814_t1;
GO

CREATE FUNCTION babel_6814_func1()
RETURNS int
AS
BEGIN
RETURN 1;
END
GO
