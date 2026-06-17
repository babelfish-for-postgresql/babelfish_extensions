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

-- Create extra tables and indexes to ensure pg_index/pg_class have enough rows
-- for consistent planner behavior in EXPLAIN tests
DECLARE @i INT = 1;
DECLARE @sql NVARCHAR(200);
WHILE @i <= 100
BEGIN
    SET @sql = 'CREATE TABLE babel_6814_extra_' + CONVERT(VARCHAR, @i) + ' (id INT)';
    EXEC(@sql);
    SET @sql = 'CREATE INDEX babel_6814_extra_idx_' + CONVERT(VARCHAR, @i) + ' ON babel_6814_extra_' + CONVERT(VARCHAR, @i) + '(id)';
    EXEC(@sql);
    SET @i = @i + 1;
END
GO

-- Create extra schemas to ensure pg_namespace has enough rows for consistent plans
DECLARE @j INT = 1;
DECLARE @sql2 NVARCHAR(200);
WHILE @j <= 500
BEGIN
    SET @sql2 = 'CREATE SCHEMA babel_6814_schema_' + CONVERT(VARCHAR, @j);
    EXEC(@sql2);
    SET @j = @j + 1;
END
GO
